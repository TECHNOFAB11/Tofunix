{
  outputs = {
    flake-parts,
    systems,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.nix-gitlab-ci.flakeModule
      ];
      systems = import systems;
      flake = {};
      perSystem = {
        pkgs,
        config,
        ...
      }: let
        tofunix-lib = pkgs.callPackage inputs.tofunix {};

        # example provider generation:
        bunny-provider = tofunix-lib.mkOpentofuProvider {
          owner = "bunnyway";
          repo = "bunnynet";
          version = "0.7.0";
          hash = "sha256-GvgAD+E/3potxlZJ3QF3UKB0r4I7lU/NGoV+/8R7RuU=";
        };
      in rec {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            mdformat.enable = true;
          };
        };
        devenv.shells.default = {
          containers = pkgs.lib.mkForce {};
          packages = [];

          pre-commit.hooks = {
            treefmt = {
              enable = true;
              packageOverrides.treefmt = config.treefmt.build.wrapper;
            };
            validate = {
              enable = true;
              name = "tofu-validate";
              pass_filenames = false;
              entry =
                (pkgs.writeShellScript "tofu-validate-hook" ''
                  nix run .#tofunix -- init -backend=false
                  nix run .#tofunix -- validate
                '')
                .outPath;
            };
          };
        };

        packages.tofunix = tofunix-lib.mkCliAio {
          plugins = [bunny-provider];
          moduleConfig = ./config;
        };

        ci = let
          cache = [
            {
              key = "tofu";
              paths = [".terraform/"];
            }
          ];
        in {
          stages = ["validate" "plan" "apply"];
          jobs = {
            "validate" = {
              inherit cache;
              stage = "validate";
              nix.deps = [packages.tofunix.gitlab];
              script = [
                "gitlab-tofunix validate"
              ];
            };
            "plan" = {
              inherit cache;
              stage = "plan";
              environment = {
                name = "default";
                action = "prepare";
              };
              resource_group = "default";
              variables.GITLAB_TOFU_PLAN_WITH_JSON = "true";
              nix.deps = [packages.tofunix.gitlab];
              script = [
                "gitlab-tofunix plan"
              ];
              artifacts = {
                access = "none";
                paths = ["plan.cache"];
                reports.terraform = "plan.json";
              };
            };
            "apply" = {
              inherit cache;
              stage = "apply";
              environment = {
                name = "default";
                action = "start";
              };
              resource_group = "default";
              rules = [
                {
                  "if" = "$CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH";
                  when = "manual";
                }
                {when = "never";}
              ];
              nix.deps = [packages.tofunix.gitlab];
              script = [
                "gitlab-tofunix apply"
              ];
            };
          };
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # flake & devenv related
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-gitlab-ci.url = "gitlab:technofab/nix-gitlab-ci/feat/v2?dir=lib";
    tofunix.url = "gitlab:technofab/tofunix?dir=lib";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
