{
  lib,
  pkgs,
  generateOptions,
  ...
}: {
  sources ? [],
  moduleConfig,
  ...
}: let
  inherit (lib) mkOption types;
  filterNonEmptyAttrsets = attrs:
    builtins.removeAttrs attrs (builtins.filter (name: builtins.getAttr name attrs == {}) (builtins.attrNames attrs));
  filterNullsRecursive = value:
    if builtins.isAttrs value
    then
      # Process attribute set
      builtins.listToAttrs (builtins.filter (
          attr:
            attr.value != null
        ) (lib.mapAttrsToList (
            name: attrValue: {
              name = name;
              value = filterNullsRecursive attrValue;
            }
          )
          value))
    else if builtins.isList value
    then
      # Process list
      builtins.filter (x: x != null) (builtins.map filterNullsRecursive value)
    else
      # Return non-collection values as-is
      value;

  imports =
    if (builtins.length sources) != 0
    then ["${generateOptions sources}/default.nix"]
    else [];
in
  lib.evalModules {
    modules =
      imports
      ++ [
        moduleConfig
        ({
          options,
          config,
          lib,
          ...
        }: {
          options = {
            final = mkOption {
              type = types.attrs;
              default = {};
            };
            finalJson = mkOption {
              readOnly = true;
              type = types.str;
              default = builtins.toJSON (config.final);
            };
            finalPackage = mkOption {
              readOnly = true;
              type = types.package;
              default = pkgs.writeText "main.tf.json" config.finalJson;
            };
            # TODO: better typing
            variable = mkOption {
              type = types.attrs;
              default = {};
            };
            locals = mkOption {
              type = types.attrs;
              default = {};
            };
            output = mkOption {
              type = types.attrs;
              default = {};
            };
            terraform = mkOption {
              type = types.submodule {
                options = {
                  required_providers = mkOption {
                    type = types.attrs;
                    default = {};
                  };
                };
              };
            };
          };

          config.final = let
            wrap = field: nest:
              filterNullsRecursive (
                lib.mapAttrs (
                  name: value: let
                    values = builtins.attrValues value;
                    computedAttrs = builtins.filter (attr: attr != null) (
                      lib.mapAttrsToList (attr: value:
                        if value.readOnly or value.internal or false
                        then attr
                        else null)
                      (options.${field}.${name}.type.getSubOptions [])
                    );
                  in
                    if value == null || values == []
                    then null
                    else
                      (
                        map (val: let
                          res = builtins.removeAttrs val computedAttrs;
                        in
                          if nest
                          then {${val._name} = res;}
                          else res)
                        values
                      )
                )
                config.${field}
              );
          in
            filterNonEmptyAttrsets {
              inherit (config) terraform output variable locals;
              provider = wrap "provider" false;
              # output = wrap "output" false;
              # variable = wrap "variable" false;
              # local = wrap "local" false;
              resource = wrap "resource" true;
              data = wrap "data" true;
              # TODO: variables etc.
            };
        })
      ];
  }
