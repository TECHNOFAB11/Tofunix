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
      flake = {
        templates."default" = {
          path = ./template;
          description = "Fully featured template/example";
        };
      };
      perSystem = {
        lib,
        pkgs,
        self',
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

          git-hooks.hooks = {
            treefmt = {
              enable = true;
              packageOverrides.treefmt = config.treefmt.build.wrapper;
            };
            convco.enable = true;
          };
        };

        doc = {
          path = ./docs;
          deps = pp: [
            pp.mkdocs-material
            pp.mkdocs-macros
            (pp.callPackage inputs.mkdocs-material-umami {})
          ];
          config = {
            site_name = "Tofunix";
            repo_name = "TECHNOFAB/tofunix";
            repo_url = "https://gitlab.com/TECHNOFAB/tofunix";
            edit_uri = "edit/main/docs/";
            theme = {
              name = "material";
              features = ["content.code.copy" "content.action.edit"];
              icon.repo = "simple/gitlab";
              logo = "images/logo.png";
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
            plugins = [
              "search"
              "material-umami"
              {
                macros = {
                  include_dir = self'.packages.optionsDocs;
                };
              }
            ];
            nav = [
              {"Introduction" = "index.md";}
              {"Usage" = "usage.md";}
              {"Pre-Commit" = "pre_commit.md";}
              {"GitLab Integration" = "gitlab_integration.md";}
              {"Reference" = "reference.md";}
              {"Options" = "options.md";}
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
          stages = ["test" "build" "deploy"];
          jobs = {
            "test:lib" = {
              stage = "test";
              script = [
                "nix run .#tests -- --junit=junit.xml"
              ];
              allow_failure = true;
              artifacts = {
                when = "always";
                reports.junit = "junit.xml";
              };
            };
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
          tflib = import ./lib {inherit lib pkgs;};
          ntlib = inputs.nixtest.lib {inherit lib pkgs;};
          doclib = inputs.nix-mkdocs.lib {inherit lib pkgs;};
        in rec {
          tests = ntlib.mkNixtest {
            modules = ntlib.autodiscover {dir = ./tests;};
            args = {
              inherit pkgs tflib ntlib;
            };
          };
          tofunix = tflib.mkCliAio {
            plugins = [pkgs.terraform-providers.vault];
            moduleConfig = {ref, ...}: {
              variable."test".default = "meow";
              provider.vault."default".address = ref.var."test";
            };
          };
          optionsDoc = doclib.mkOptionDocs {
            module = {
              imports = [
                tflib.module
                {
                  _module.args.pkgs = pkgs;
                }
              ];
            };
            roots = [
              {
                url = "https://gitlab.com/TECHNOFAB/tofunix/-/blob/main/lib";
                path = toString ./lib;
              }
            ];
          };
          optionsDocs = pkgs.runCommand "options-docs" {} ''
            mkdir -p $out
            ln -s ${optionsDoc} $out/options.md
          '';
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-gitlab-ci.url = "gitlab:TECHNOFAB/nix-gitlab-ci/2.1.0?dir=lib";
    nixtest.url = "gitlab:TECHNOFAB/nixtest?dir=lib";
    nix-mkdocs.url = "gitlab:TECHNOFAB/nixmkdocs/v1.0.0?dir=lib";
    mkdocs-material-umami.url = "gitlab:TECHNOFAB/mkdocs-material-umami";
  };
}
