{
  options,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkOption types mapAttrs mapAttrsToList;
  filterNonEmptyAttrsets = attrs:
    builtins.removeAttrs attrs (builtins.filter (name: builtins.getAttr name attrs == {}) (builtins.attrNames attrs));
  filterNullsRecursive = value:
    if builtins.isAttrs value
    then
      # Process attribute set
      builtins.listToAttrs (builtins.filter (
          attr:
            attr.value != null
        ) (mapAttrsToList (
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
in {
  _file = ./module.nix;
  options = {
    final = mkOption {
      type = types.attrs;
      default = {};
      internal = true;
    };
    finalJson = mkOption {
      type = types.str;
      default = builtins.toJSON (config.final);
      internal = true;
    };
    finalPackage = mkOption {
      type = types.package;
      default = pkgs.writeText "main.tf.json" config.finalJson;
      internal = true;
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
    data = mkOption {
      type = types.attrs;
      default = {};
    };
    resource = mkOption {
      type = types.attrs;
      default = {};
    };
    terraform = mkOption {
      default = {};
      type = types.submodule {
        options = {
          required_providers = mkOption {
            type = types.attrs;
            default = {};
          };
          backend = mkOption {
            type = types.nullOr types.attrs;
            default = null;
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
        mapAttrs (
          name: value: let
            values = builtins.attrValues value;
            computedAttrs = builtins.filter (attr: attr != null) (
              mapAttrsToList (attr: value:
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
                  if nest && val ? _name
                  then {${val._name} = res;}
                  else res)
                values
              )
        )
        config.${field} or {}
      );
  in
    filterNonEmptyAttrsets {
      inherit (config) output variable locals;
      terraform = filterNullsRecursive config.terraform;
      provider = wrap "provider" false;
      resource = wrap "resource" true;
      data = wrap "data" true;
    };
}
