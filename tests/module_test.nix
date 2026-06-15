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
    hash = "sha256-m/lfI5CSZV2Voo5Lhs653cpggR4MEbv9eeU8sDLK2jE=";
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
      {
        name = "meta-arguments generate correctly";
        type = "script";
        script = let
          eval = tflib.mkModule {
            sources = [nullPlugin];
            moduleConfig = {ref, ...}: {
              resource.null_resource.primary = {};
              resource.null_resource.example = {
                depends_on = [ref.null_resource."primary"];
                lifecycle = {
                  prevent_destroy = true;
                  create_before_destroy = true;
                  ignore_changes = ["triggers"];
                };
              };
            };
          };
          jsonFile = eval.config.finalPackage;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.jq]}
            ${ntlib.helpers.scriptHelpers}

            assert "-f ${jsonFile}" "JSON file should be created"

            # Check lifecycle block exists
            assert "$(jq '.resource.null_resource[] | select(.example != null) | .example | has("lifecycle")' ${jsonFile}) = true" "should have lifecycle block"

            # Check lifecycle sub-fields
            assert "$(jq '.resource.null_resource[] | select(.example != null) | .example.lifecycle.prevent_destroy' ${jsonFile}) = true" "prevent_destroy should be true"
            assert "$(jq '.resource.null_resource[] | select(.example != null) | .example.lifecycle.create_before_destroy' ${jsonFile}) = true" "create_before_destroy should be true"
            assert "$(jq -r '.resource.null_resource[] | select(.example != null) | .example.lifecycle.ignore_changes[0]' ${jsonFile}) = triggers" "ignore_changes should contain triggers"

            # Check depends_on
            assert "$(jq -r '.resource.null_resource[] | select(.example != null) | .example.depends_on[0]' ${jsonFile}) = null_resource.primary" "depends_on should reference primary"

            # Check that lifecycle is not set on primary
            assert "$(jq '.resource.null_resource[] | select(.primary != null) | .primary | has("lifecycle")' ${jsonFile}) = false" "primary should not have lifecycle block"
          '';
      }
    ];
  };
}
