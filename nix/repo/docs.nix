{inputs, ...}: let
  inherit (inputs) pkgs doclib tflib;

  optionsDoc = doclib.mkOptionDocs {
    module = tflib.module;
    roots = [
      {
        url = "https://gitlab.com/TECHNOFAB/tofunix/-/blob/main/lib";
        path = "${inputs.self}/lib";
      }
    ];
  };
  nullPlugin = tflib.mkOpentofuProvider {
    owner = "hashicorp";
    repo = "null";
    version = "3.2.4";
    hash = "sha256-kR+oynTYqzEAgXr0Hc9uL7ihQUuNQz6nT4kUoKYVtc0=";
  };
  exampleProviderDoc = doclib.mkOptionDocs {
    module.imports = [
      "${tflib.generateOptions [nullPlugin]}/default.nix"
    ];
  };
  optionsDocs = pkgs.runCommand "options-docs" {} ''
    mkdir -p $out
    ln -s ${optionsDoc} $out/options.md
    ln -s ${exampleProviderDoc} $out/provider_options.md
  '';
in
  (doclib.mkDocs {
    docs."default" = {
      base = "${inputs.self}";
      path = "${inputs.self}/docs";
      material = {
        enable = true;
        colors = {
          primary = "yellow";
          accent = "amber";
        };
        umami = {
          enable = true;
          src = "https://analytics.tf/umami";
          siteId = "79cb89ba-7008-4121-b94c-aac295dc3215";
          domains = ["tofunix.projects.tf"];
        };
      };
      macros = {
        enable = true;
        includeDir = toString optionsDocs;
      };
      config = {
        site_name = "Tofunix";
        site_url = "https://tofunix.projects.tf";
        repo_name = "TECHNOFAB/tofunix";
        repo_url = "https://gitlab.com/TECHNOFAB/tofunix";
        extra_css = ["style.css"];
        theme = {
          logo = "images/logo.svg";
          icon.repo = "simple/gitlab";
          favicon = "images/logo.svg";
        };
        nav = [
          {"Introduction" = "index.md";}
          {"Usage" = "usage.md";}
          {"Pre-Commit" = "pre_commit.md";}
          {"GitLab Integration" = "gitlab_integration.md";}
          {"Reference" = "reference.md";}
          {"Options" = "options.md";}
          {"Examples" = "examples.md";}
          {"Example Provider Options" = "example_provider_options.md";}
          {"Debugging" = "debugging.md";}
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
      };
    };
  }).packages
