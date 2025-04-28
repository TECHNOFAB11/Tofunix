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
        inputs.nix-mkdocs.flakeModule
      ];
      systems = import systems;
      perSystem = {
        pkgs,
        lib,
        config,
        ...
      }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            mdformat.enable = true;
          };
          settings.formatter.mdformat.command = let
            pkg = pkgs.python3.withPackages (p: [
              p.mdformat
              p.mdformat-mkdocs
            ]);
          in
            lib.mkForce "${pkg}/bin/mdformat";
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

        doc = {
          path = ./docs;
          deps = pp: [pp.mkdocs-material (pp.callPackage inputs.mkdocs-material-umami {})];
          config = {
            site_name = "Tofunix";
            repo_name = "TECHNOFAB/tofunix";
            repo_url = "https://gitlab.com/TECHNOFAB/tofunix";
            edit_uri = "edit/main/docs/";
            theme = {
              name = "material";
              features = ["content.code.copy" "content.action.edit"];
              icon = {
                logo = "simple/opentofu";
                repo = "simple/gitlab";
              };
              favicon = "images/favicon.png";
              palette = [
                {
                  scheme = "default";
                  media = "(prefers-color-scheme: light)";
                  primary = "yellow";
                  accent = "amber";
                  toggle = {
                    icon = "material/brightness-7";
                    name = "Switch to dark mode";
                  };
                }
                {
                  scheme = "slate";
                  media = "(prefers-color-scheme: dark)";
                  primary = "yellow";
                  accent = "amber";
                  toggle = {
                    icon = "material/brightness-4";
                    name = "Switch to light mode";
                  };
                }
              ];
            };
            plugins = ["search" "material-umami"];
            nav = [
              {"Introduction" = "index.md";}
            ];
            markdown_extensions = [
              {
                "pymdownx.highlight".pygments_lang_class = true;
              }
              "pymdownx.inlinehilite"
              "pymdownx.snippets"
              "pymdownx.superfences"
              "fenced_code"
              "admonition"
            ];
            extra.analytics = {
              provider = "umami";
              site_id = "79cb89ba-7008-4121-b94c-aac295dc3215";
              src = "https://analytics.tf/umami";
              domains = "tofunix.projects.tf";
              feedback = {
                title = "Was this page helpful?";
                ratings = [
                  {
                    icon = "material/thumb-up-outline";
                    name = "This page is helpful";
                    data = "good";
                    note = "Thanks for your feedback!";
                  }
                  {
                    icon = "material/thumb-down-outline";
                    name = "This page could be improved";
                    data = "bad";
                    note = "Thanks for your feedback!";
                  }
                ];
              };
            };
          };
        };

        ci = {
          stages = ["build" "deploy"];
          jobs = {
            "docs" = {
              stage = "build";
              script = [
                # sh
                ''
                  nix build .#docs:default
                  mkdir -p public
                  cp -r result/. public/
                ''
              ];
              artifacts.paths = ["public"];
            };
            "pages" = {
              nix.enable = false;
              image = "alpine:latest";
              stage = "deploy";
              script = ["true"];
              artifacts.paths = ["public"];
              rules = [
                {
                  "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
                }
              ];
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
    nix-gitlab-ci.url = "gitlab:TECHNOFAB/nix-gitlab-ci/feat/v2?dir=lib";
    nix-mkdocs.url = "gitlab:TECHNOFAB/nixmkdocs?dir=lib";
    mkdocs-material-umami.url = "gitlab:technofab/mkdocs-material-umami";
  };
}
