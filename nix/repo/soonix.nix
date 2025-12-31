{
  inputs,
  cell,
  ...
}: let
  inherit (inputs) soonix;
  inherit (cell) ci;
in
  (soonix.make {
    hooks = {
      ci = ci.soonix;
      renovate = {
        output = ".gitlab/renovate.json5";
        data = {
          extends = ["config:recommended"];
          postUpgradeTasks = {
            commands = [
              "nix-portable nix run .#soonix:update"
            ];
            executionMode = "branch";
          };
          lockFileMaintenance = {
            enabled = true;
            extends = ["schedule:monthly"];

            branchTopic = "lock-file-maintenance-{{packageFile}}";
            commitMessageExtra = "({{packageFile}})";
          };
          nix.enabled = true;
          gitlabci.enabled = false;
        };
        hook = {
          mode = "copy";
          gitignore = false;
        };
        opts.format = "json";
      };
    };
  }).config
