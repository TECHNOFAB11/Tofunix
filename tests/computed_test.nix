{
  tflib,
  ntlib,
  ...
}: let
  inherit (ntlib) asserts;

  computed = {
    type = "string";
    computed = true;
  };
  optionalComputed = computed // {optional = true;};

  generated = tflib.generateOptionsForProvider {
    name = "example-demo";
    provider = "demo";
    source = "example/demo";
    version = "1.0.0";
    spec = {
      provider.block.attributes = {};
      resource_schemas.demo_item.block = {
        attributes = {
          result = computed;
          override = optionalComputed;
          object = {
            optional = true;
            nested_type = {
              nesting_mode = "single";
              attributes.result = computed;
              attributes.override = optionalComputed;
            };
          };
        };
        block_types.child = {
          nesting_mode = "list";
          block.attributes.result = computed;
          block.attributes.override = optionalComputed;
        };
      };
      data_source_schemas.demo_lookup.block.attributes = {
        result = computed;
        override = optionalComputed;
      };
    };
  };

  load = module:
    (tflib.mkModule {
      moduleConfig = {
        imports = ["${generated}" module];
        resource.demo_item.example = {};
        data.demo_lookup.example = {};
      };
    }).config.final;

  configured = load ({ref, ...}: {
    resource.demo_item.example = {
      override = "configured";
      object.override = "configured";
      child.override = "configured";
    };
    data.demo_lookup.example.override = "configured";
    output.resource_result.value = builtins.toString ref.demo_item.example.result;
    output.data_result.value = builtins.toString ref.data.demo_lookup.example.result;
  });

  item = (builtins.head configured.resource.demo_item).example;
  lookup = (builtins.head configured.data.demo_lookup).example;
in {
  suites."Computed attributes" = {
    pos = __curPos;
    tests = [
      {
        name = "computed-only assignments are rejected";
        type = "assertions";
        assertions = {
          "resource attribute" = asserts.throws (load {
            resource.demo_item.example.result = "invalid";
          });
          "data attribute" = asserts.throws (load {
            data.demo_lookup.example.result = "invalid";
          });
          "nested attribute" = asserts.throws (load {
            resource.demo_item.example.object.result = "invalid";
          });
          "block attribute" = asserts.throws (load {
            resource.demo_item.example.child.result = "invalid";
          });
          "reference assignment" = asserts.throws (load {
            resource.demo_item.example.result = "\${var.value}";
          });
          "forced assignment" = asserts.throws (load ({lib, ...}: {
            resource.demo_item.example.result = lib.mkForce "invalid";
          }));
        };
      }
      {
        name = "optional computed attributes remain configurable";
        type = "assertions";
        assertions = {
          "resource attribute" = asserts.eq "configured" item.override;
          "nested attribute" = asserts.eq "configured" item.object.override;
          "block attribute" = asserts.eq "configured" item.child.override;
          "data attribute" = asserts.eq "configured" lookup.override;
          "reference assignment" = let
            overrideResult = (builtins.head (load {resource.demo_item.example.override = "\${var.value}";}).resource.demo_item).example;
          in
            asserts.eq "\${var.value}" overrideResult.override;
        };
      }
      {
        name = "computed fields remain accessible through references";
        type = "assertions";
        assertions = {
          "resource reference" = asserts.eq "\${demo_item.example.result}" configured.output.resource_result.value;
          "data reference" = asserts.eq "\${data.demo_lookup.example.result}" configured.output.data_result.value;
        };
      }
      {
        name = "unset computed values are omitted from output";
        type = "assertions";
        assertions = {
          "resource result omitted" = asserts.missingAttr "result" item;
          "nested object result omitted" = asserts.missingAttr "result" item.object;
          "block result omitted" = asserts.missingAttr "result" item.child;
          "data result omitted" = asserts.missingAttr "result" lookup;
        };
      }
    ];
  };
}
