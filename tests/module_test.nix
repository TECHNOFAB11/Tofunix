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
in {
  suites."Module" = {
    pos = __curPos;
    tests = [
      {
        name = "generates correct JSON structure";
        type = "script";
        script = let
          eval = tflib.mkModule {
            sources = [nullPlugin];
            moduleConfig = {
              variable.test_var = {
                type = "string";
                default = "hello";
              };
              resource.null_resource.example = {
                triggers = {
                  value = "\${var.test_var}";
                };
              };
              output.test_out = {
                value = "\${null_resource.example.id}";
              };
              terraform.backend.s3 = {
                bucket = "my-bucket";
              };
            };
          };
          jsonFile = eval.config.finalPackage;
          escapedReference = "\\\${var.test_var}";
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.jq]}
            ${ntlib.helpers.scriptHelpers}

            assert "-f ${jsonFile}" "JSON file should be created"

            # Check top-level keys
            assert "$(jq 'has("variable")' ${jsonFile}) = true" "should have 'variable' key"
            assert "$(jq 'has("resource")' ${jsonFile}) = true" "should have 'resource' key"
            assert "$(jq 'has("output")' ${jsonFile}) = true" "should have 'output' key"
            assert "$(jq 'has("terraform")' ${jsonFile}) = true" "should have 'terraform' key"

            # Check content
            assert "'$(jq -r '.variable.test_var.default' ${jsonFile})' = 'hello'" "variable default should be correct"
            assert "'$(jq -r '.resource.null_resource.[0].example.triggers.value' ${jsonFile})' = '${escapedReference}'" "resource trigger should be a reference"
            assert "'$(jq -r '.terraform.backend.s3.bucket' ${jsonFile})' = 'my-bucket'" "terraform backend should be configured"
          '';
      }
      {
        name = "reference generation works correctly";
        expected = {
          var = "\${var.test_var}";
          resource = "\${null_resource.example.id}";
          data = "\${data.null_data_source.example.inputs}";
        };
        actual = let
          eval = tflib.mkModule {
            sources = [nullPlugin];
            moduleConfig = {
              variable.test_var.default = "a";
              resource.null_resource."example".id = "dummy-id";
              data.null_data_source."example".inputs.test = "dummy-body";
            };
          };
        in {
          var = eval._module.args.ref.var.test_var;
          resource = eval._module.args.ref.null_resource.example.id;
          data = eval._module.args.ref.data.null_data_source.example.inputs;
        };
      }
    ];
  };
}
