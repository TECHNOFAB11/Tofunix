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

        packages = let
          lib = pkgs.callPackage ./lib {};
        in {
          tofunix = lib.mkCliAio {
            plugins = [pkgs.terraform-providers.vault];
            moduleConfig = {ref, ...}: {
              variable."test".default = "meow";
              provider.vault."default".address = ref.var."test";
            };
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
  };
}
