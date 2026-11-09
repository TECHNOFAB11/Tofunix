{
  tflib,
  ntlib,
  ...
}: let
  inherit (ntlib) asserts;

  block = {
    mode ? "list",
    minimum ? 0,
    maximum ? 0,
  }: {
    nesting_mode = mode;
    min_items = minimum;
    max_items = maximum;
    block.attributes.label = {
      type = "string";
      required = true;
    };
  };

  generated = tflib.generateOptionsForProvider {
    name = "example-demo";
    provider = "demo";
    source = "example/demo";
    version = "1.0.0";
    spec = {
      provider.block.attributes = {};
      resource_schemas.demo_item.block.block_types = {
        child = block {
          minimum = 2;
          maximum = 3;
        };
        optional = block {maximum = 1;};
        unlimited = block {};
        unique = block {
          mode = "set";
          maximum = 1;
        };
        single = block {mode = "single";};
        group = block {mode = "group";};
        named = block {mode = "map";};
        parent = {
          nesting_mode = "single";
          block.block_types.child = block {
            minimum = 1;
            maximum = 1;
          };
        };
      };
      data_source_schemas.demo_lookup.block.block_types.child = block {
        minimum = 1;
        maximum = 1;
      };
    };
  };

  entry = label: {inherit label;};

  required = [(entry "a") (entry "b")];

  evalModule = module:
    (tflib.mkModule {
      moduleConfig.imports = ["${generated}" module];
    }).config.final != {};

  resource = extra: {resource.demo_item.example = {child = required;} // extra;};
in {
  suites."Nested blocks" = {
    pos = __curPos;
    tests = [
      {
        name = "cardinality constraints";
        type = "assertions";
        assertions = {
          "omitting required blocks throws" =
            asserts.throws (evalModule {resource.demo_item.example = {};});

          "fewer than min_items throws" =
            asserts.throws (evalModule {resource.demo_item.example.child = [(entry "a")];});

          "empty list for required block throws" =
            asserts.throws (evalModule {resource.demo_item.example.child = [];});

          "exceeding max_items throws" =
            asserts.throws (evalModule {resource.demo_item.example.child = required ++ required;});

          "min_items boundary is accepted" =
            evalModule (resource {});

          "max_items boundary is accepted" =
            evalModule {resource.demo_item.example.child = required ++ [(entry "c")];};

          "unlimited blocks accept arbitrarily many items" =
            evalModule (resource {unlimited = required ++ required;});

          "omitted optional block evaluates cleanly" =
            evalModule (resource {});

          "empty list on optional block evaluates cleanly" =
            evalModule (resource {optional = [];});

          "limits are checked after merging module definitions" = asserts.throws (evalModule {
            imports = [
              (resource {optional = [(entry "a")];})
              {resource.demo_item.example.optional = [(entry "b")];}
            ];
          });
        };
      }
      {
        name = "nesting modes and syntax shorthand";
        type = "assertions";
        assertions = {
          "single block shorthand accepts single object" = evalModule (resource {
            optional = entry "a";
            group = entry "a";
          });

          "single element array shorthand is accepted" =
            evalModule (resource {single = [(entry "a")];});

          "single mode rejects more than one block" =
            asserts.throws (evalModule (resource {single = required;}));

          "group mode rejects more than one block" =
            asserts.throws (evalModule (resource {group = required;}));

          "set mode rejects exceeding max_items" =
            asserts.throws (evalModule (resource {unique = required;}));

          "map mode accepts labeled attrset" = evalModule (resource {
            named = {
              first = entry "a";
              second = entry "b";
            };
          });

          "map mode accepts list of labeled attrsets" = evalModule (resource {
            named = [
              {first = entry "a";}
              {second = entry "b";}
            ];
          });

          "map mode rejects unlabeled item body" =
            asserts.throws (evalModule (resource {named = entry "a";}));
        };
      }
      {
        name = "hierarchy data sources and references";
        type = "assertions";
        assertions = {
          "optional parent omitted without children evaluates cleanly" =
            evalModule (resource {});

          "optional parent without required grandchild throws" =
            asserts.throws (evalModule (resource {parent = {};}));

          "optional parent with required grandchild succeeds" =
            evalModule (resource {parent.child = entry "a";});

          "data source required block cannot be omitted" =
            asserts.throws (evalModule {data.demo_lookup.example = {};});

          "data source block exceeding max_items throws" =
            asserts.throws (evalModule {data.demo_lookup.example.child = required;});

          "data source valid block evaluates cleanly" =
            evalModule {data.demo_lookup.example.child = entry "a";};

          "references inside nested block attributes evaluate cleanly" =
            evalModule (resource {optional.label = "\${var.label}";});
        };
      }
    ];
  };
}
