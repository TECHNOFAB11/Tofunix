{
  lib ? pkgs.lib,
  pkgs,
  ...
}: let
  inherit (lib) evalModules;
  # generates the terraform provider spec (json schema) for multiple sources
  generateSpec =
    # sources: list[str "<org>/<provider>@<version>"], example: ["hashicorp/vault@0.0.1"]
    #  optionally with registry (<registry>/<org>/...)
    # or instead of strings these can also be terraform provider packages
    sources:
      import ./spec.nix {inherit lib pkgs sources;};

  # generates the nix options for a given provider spec
  generateOptionsForProvider = spec:
    import ./generator.nix {
      inherit lib pkgs;
      fullSpec = spec;
    };

  # generates the nix options for all the given sources
  generateOptions = sources: let
    specs = generateSpec sources;

    generated =
      map (provider: let
        spec = builtins.getAttr provider specs;
      in {
        drv = generateOptionsForProvider spec;
        inherit spec;
      })
      (builtins.attrNames specs);

    files = builtins.concatStringsSep "\n" (map (
        gen: "./${gen.spec.name}-${gen.spec.version}.nix"
      )
      generated);
    commands = builtins.concatStringsSep "\n" (
      map (
        gen: "cp ${gen.drv} $out/${gen.spec.name}-${gen.spec.version}.nix"
      )
      generated
    );
    imports =
      # nix
      "{ imports = [${files}]; }";
  in
    pkgs.runCommand "tofunix-options" {
      buildInputs = [pkgs.nixpkgs-fmt];
    } ''
      mkdir -p $out
      ${commands}
      echo '${imports}' > $out/default.nix
      nixpkgs-fmt $out/default.nix
    '';

  module = ./module.nix;
  mkModule = {
    sources ? [],
    moduleConfig,
  }: let
    imports =
      if (builtins.length sources) != 0
      then ["${generateOptions sources}/default.nix"]
      else [];
  in
    evalModules {
      modules =
        imports
        ++ [
          moduleConfig
          module
          {
            _module.args = {
              inherit pkgs utils;
            };
          }
        ];
    };

  mkCli = import ./cli.nix {inherit lib pkgs;};
  mkCliAio = {
    plugins,
    moduleConfig,
  }:
    mkCli {
      inherit plugins;
      module = mkModule {
        sources = plugins;
        inherit moduleConfig;
      };
    };

  utils = import ./utils.nix {inherit lib;};
  packaging = import ./packaging.nix {inherit lib pkgs;};
in {
  inherit
    generateSpec
    generateOptionsForProvider
    generateOptions
    module
    mkModule
    mkCli
    mkCliAio
    utils
    ;
  inherit
    (packaging)
    mkTerraformProvider
    fetchProviderSpec
    mkOpentofuProvider
    ;
}
