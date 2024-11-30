{
  outputs = {
    systems,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.nix-gitlab-ci.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = import systems;
      perSystem = {
        pkgs,
        lib,
        config,
        inputs',
        ...
      }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            mdformat.enable = true;
          };
        };

        devenv.shells.default = {
          containers = lib.mkForce {};
          packages = with pkgs; [
            opentofu
          ];

          pre-commit = {
            hooks = {
              treefmt = {
                enable = true;
                packageOverrides.treefmt = config.treefmt.build.wrapper;
              };
            };
          };
        };

        legacyPackages = {
          module = lib.evalModules {
            modules = [
              # ./result
              ./bunny-provider.nix

              ({
                options,
                config,
                lib,
                ...
              }: let
                inherit (lib) mkOption types;
                filterNonEmptyAttrsets = attrs:
                  builtins.removeAttrs attrs (builtins.filter (name: attrs.${name} == {}) (builtins.attrNames attrs));
                filterNullsRecursive = value:
                  if builtins.isAttrs value
                  then
                    # Process attribute set
                    builtins.listToAttrs (builtins.filter (
                        attr:
                          attr.value != null
                      ) (lib.mapAttrsToList (
                          name: attrValue: {
                            name = name;
                            value = filterNullsRecursive attrValue;
                          }
                        )
                        value))
                  else if builtins.isList value
                  then
                    # Process list
                    builtins.filter (x: x != null) (builtins.map filterNullsRecursive value)
                  else
                    # Return non-collection values as-is
                    value;
              in {
                options = {
                  final = mkOption {
                    type = types.attrs;
                    default = {};
                  };
                  finalJson = mkOption {
                    readOnly = true;
                    type = types.str;
                    default = builtins.toJSON (config.final);
                  };
                  finalPackage = mkOption {
                    readOnly = true;
                    type = types.package;
                    default = pkgs.writeText "main.tf.json" config.finalJson;
                  };
                };

                config.final = let
                  wrap = field: nest:
                    filterNullsRecursive (
                      lib.mapAttrs (
                        name: value: let
                          values = builtins.attrValues value;
                          computedAttrs = builtins.filter (attr: attr != null) (
                            lib.mapAttrsToList (attr: value:
                              if value.readOnly or value.internal or false
                              then attr
                              else null)
                            (options.${field}.${name}.type.getSubOptions [])
                          );
                        in
                          if values == []
                          then null
                          else
                            (
                              map (val: let
                                res = builtins.removeAttrs val computedAttrs;
                              in
                                if nest
                                then {${val._name} = res;}
                                else res)
                              values
                            )
                      )
                      config.${field}
                    );
                in
                  filterNonEmptyAttrsets {
                    provider = wrap "providers" false;
                    resource = wrap "resource" true;
                    data = wrap "data" true;
                  };

                config = {
                  providers.bunnynet.default = {};
                  providers.bunnynet.somealias = {
                    api_key = "some_api_key";
                  };
                  resource.bunnynet_pullzone."test" = {
                    name = "Some Pullzone";
                  };
                  resource.bunnynet_compute_script."meow" = {
                    type = "standalone";
                    name = config.resource.bunnynet_pullzone.test.cdn_domain;

                    content = '''';
                  };
                };
              })
            ];
          };
        };

        packages = {
          provider = pkgs.callPackage ./generator.nix {
            source = "BunnyWay/bunnynet";
            version = "0.4.1";
          };
          test = pkgs.opentofu.withPlugins (p: [
            p.random
          ]);
          testModule = pkgs.callPackage ./module.nix {
            plugins = with pkgs.terraform-providers; [
              random
              time

              inputs'.ntp-bin.legacyPackages.providers.hashicorp.nomad
            ];
          };
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gitlab-ci.url = "gitlab:TECHNOFAB/nix-gitlab-ci?dir=lib";

    ntp-bin = {
      url = "github:nix-community/nixpkgs-terraform-providers-bin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
