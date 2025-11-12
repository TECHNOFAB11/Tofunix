{
  pkgs,
  tflib,
  ntlib,
  ...
}: let
  nullPlugin = tflib.mkOpentofuProvider {
    owner = "hashicorp";
    repo = "null";
    version = "3.2.4";
    hash = "sha256-kR+oynTYqzEAgXr0Hc9uL7ihQUuNQz6nT4kUoKYVtc0=";
  };
  kubernetesPlugin = tflib.mkOpentofuProvider {
    owner = "hashicorp";
    repo = "kubernetes";
    version = "2.38.0";
    hash = "sha256-n8dCz7DN6B4TOjmCNcl9nARjZ8B6KedRPL/8AwMQslE=";
  };
in {
  suites."CLI" = {
    pos = __curPos;
    tests = [
      {
        name = "mkCli generates a valid wrapper script";
        type = "script";
        script = let
          cli = tflib.mkCli {
            tf-pkg = pkgs.opentofu;
            module = tflib.mkModule {moduleConfig = {};};
          };
          cliScript = "${cli}/bin/tofunix";
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}
            assert "-x ${cliScript}" "CLI script should be executable"
            assert_file_contains "${cliScript}" "mktemp -d" "should create a temporary directory"
            assert_file_contains "${cliScript}" "trap cleanup EXIT" "should set up a cleanup trap"
            assert_file_contains "${cliScript}" "-chdir=" "should use -chdir with the temp dir"
            assert_file_contains "${cliScript}" "${pkgs.opentofu}/bin/tofu" "should call the correct opentofu binary"
          '';
      }
      {
        name = "mkCliAio generates a valid all-in-one wrapper";
        type = "script";
        script = let
          cli = tflib.mkCliAio {
            plugins = [];
            moduleConfig = {
              variable.foo.default = "bar";
            };
          };
          cliScript = "${cli}/bin/tofunix";
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}
            assert "-x ${cliScript}" "CLI script should be executable"
            assert_file_contains "${cliScript}" "ln -s" "should symlink the generated config"
            assert_file_contains "${cliScript}" "main.tf.json" "should reference the generated json config"
          '';
      }
      {
        name = "GitLab CI wrapper generation";
        type = "script";
        script = let
          cli = tflib.mkCli {
            module = tflib.mkModule {moduleConfig = {};};
          };
          gitlabCli = cli.gitlab;
          cliScript = "${gitlabCli}/bin/gitlab-tofunix";
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}
            assert "-x ${cliScript}" "GitLab CLI script should be executable"
            assert_file_contains "${cliScript}" "ln -s .* main.tf.json" "should symlink config to main.tf.json"
            assert_file_contains "${cliScript}" "trap 'rm -f main.tf.json' EXIT" "should clean up the symlink"
            assert_file_contains "${cliScript}" "/bin/gitlab-tofu" "should call the gitlab-tofu helper"
          '';
      }
      {
        name = "Tofu validate";
        type = "script";
        script = let
          tofunix = tflib.mkCliAio {
            plugins = [nullPlugin kubernetesPlugin];
            moduleConfig = {ref, ...}: {
              variable."test".default = "meow";
              provider.null."default".alias = "meow";
              resource.null_resource."example".triggers.value = ref.var."test";
            };
          };
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.coreutils]}
            ${tofunix}/bin/tofunix init
            ${tofunix}/bin/tofunix validate
          '';
      }
    ];
  };
}
