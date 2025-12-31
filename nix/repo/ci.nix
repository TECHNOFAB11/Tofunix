{inputs, ...}: let
  inherit (inputs) cilib;
in
  cilib.mkCI {
    pipelines."default" = {
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
  }
