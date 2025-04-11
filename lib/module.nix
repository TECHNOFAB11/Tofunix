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

          # NOTE: dynamic accessors dont exist in Nix, but instead we could use
          #  __toString and __functor to expand on this?
          #  depending on how often sub-attrs are needed we could do this:
          #  {
          #    _attrs = [name];
          #    __functor = self: attr: self // { attrs = self.attrs ++ [attr]; };
          #    __toString = self: "\${var.${concatStringSep "." self.attrs}}"
          #  }
          #  or maybe add an attr "get" which then does that
          config._module.args.ref =
            {
              var = builtins.listToAttrs (builtins.map (name: {
                inherit name;
                value = "\${var.${name}}";
              }) (builtins.attrNames config.variable));
              local = builtins.listToAttrs (builtins.map (name: {
                inherit name;
                value = "\${local.${name}}";
              }) (builtins.attrNames config.locals));
              data = builtins.listToAttrs (builtins.map (data: {
                name = data;
                value = builtins.listToAttrs (builtins.map (name: {
                  inherit name;
                  value = builtins.listToAttrs (builtins.map (attr: {
                    name = attr;
                    value = "\${data.${data}.${name}.${attr}}";
                  }) (builtins.attrNames (config.data.${data}.${name})));
                }) (builtins.attrNames config.data.${data}));
              }) (builtins.attrNames config.data));
            }
            // (builtins.listToAttrs (builtins.map (resource: {
              name = resource;
              value = builtins.listToAttrs (builtins.map (name: {
                inherit name;
                value = builtins.listToAttrs (builtins.map (attr: {
                  name = attr;
                  value = "\${${resource}.${name}.${attr}}";
                }) (builtins.attrNames config.resource.${resource}.${name}));
              }) (builtins.attrNames config.resource.${resource}));
            }) (builtins.attrNames config.resource)));

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
