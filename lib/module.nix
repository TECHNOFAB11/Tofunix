{
  options,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    mkOptionType
    isType
    literalExpression
    mkOption
    types
    filterAttrs
    mapAttrs
    mapAttrsToList
    ;

  unsetType = mkOptionType {
    name = "unset";
    description = "unset";
    descriptionClass = "noun";
    check = isType "unset";
  };
  unset = {
    _type = "unset";
  };
  isUnset = isType "unset";
  unsetOr = typ:
    (types.either unsetType typ)
    // {
      inherit (typ) description getSubOptions;
    };

  filterUnset = value:
    if builtins.isAttrs value && !builtins.hasAttr "_type" value
    then let
      filteredAttrs = builtins.mapAttrs (n: v: filterUnset v) value;
    in
      filterAttrs (name: value: (!isUnset value)) filteredAttrs
    else if builtins.isList value
    then builtins.filter (elem: !isUnset elem) (map filterUnset value)
    else value;

  mkUnsetOption = args:
    mkOption args
    // {
      type = unsetOr args.type;
      default = args.default or unset;
      defaultText = literalExpression "unset";
    };
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

    generated = {
      provider = mkOption {
        type = types.attrsOf types.unspecified;
        internal = true;
        default = {};
      };
      resource = mkOption {
        type = types.attrsOf types.unspecified;
        internal = true;
        default = {};
      };
      data = mkOption {
        type = types.attrsOf types.unspecified;
        internal = true;
        default = {};
      };
    };

    # TODO: better typing
    variable = mkUnsetOption {
      type = types.attrs;
      description = ''
        Terraform variables.
      '';
    };
    locals = mkUnsetOption {
      type = types.attrs;
      description = ''
        Terraform locals.
      '';
    };
    output = mkUnsetOption {
      type = types.attrs;
      description = ''
        Terraform outputs.
      '';
    };
    provider = mkOption {
      type = types.submodule {};
      default = {};
      description = ''
        Terraform providers. Sub-Options are automatically defined by generated providers.
      '';
    };
    data = mkOption {
      type = types.submodule {};
      default = {};
      description = ''
        Terraform data. Sub-Options are automatically defined by generated providers.
      '';
    };
    resource = mkOption {
      type = types.submodule {};
      default = {};
      description = ''
        Terraform resources. Sub-Options are automatically defined by generated providers.
      '';
    };
    terraform = mkUnsetOption {
      type = types.submodule {
        options = {
          required_providers = mkUnsetOption {
            type = types.attrs;
            description = ''
              Required providers. Automatically contains imported generated providers.
            '';
          };
          backend = mkUnsetOption {
            type = types.attrs;
            description = ''
              Terraform backend settings.
            '';
          };
        };
      };
      description = ''
        Terraform settings.
      '';
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
  config._module.args.ref = let
    wrap = value: {
      __chain = value;
      __functor = self: arg: self // {__chain = self.__chain + arg;};
      __toString = self: "\${${self.__chain}}";
    };
  in
    {
      var = builtins.listToAttrs (builtins.map (name: {
        inherit name;
        value = wrap "var.${name}";
      }) (builtins.attrNames config.variable));
      local = builtins.listToAttrs (builtins.map (name: {
        inherit name;
        value = wrap "local.${name}";
      }) (builtins.attrNames config.locals));
      data = builtins.listToAttrs (builtins.map (data: {
        name = data;
        value = builtins.listToAttrs (builtins.map (name: {
          inherit name;
          value = builtins.listToAttrs (builtins.map (attr: {
            name = attr;
            value = wrap "data.${data}.${name}.${attr}";
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
          value = wrap "${resource}.${name}.${attr}";
        }) (builtins.attrNames config.resource.${resource}.${name}));
      }) (builtins.attrNames config.resource.${resource}));
    }) (builtins.attrNames config.resource)));

  config.final = let
    wrap = field: nest:
      filterUnset (
        if config ? ${field}
        then
          mapAttrs (
            name: value: let
              values = builtins.attrValues value;
              computedAttrs = builtins.filter (attr: attr != null) (
                mapAttrsToList (attr: value:
                  if value.readOnly or value.internal or false
                  then attr
                  else null)
                (config.generated.${field}.${name}.type.getSubOptions [])
              );
            in
              if isUnset value || values == []
              then unset
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
          config.${field}
        else unset
      );
  in
    # need to filter out {} separately oof
    filterAttrs (name: value: value != {}) (filterUnset {
      inherit (config) output variable locals terraform;
      provider = wrap "provider" false;
      resource = wrap "resource" true;
      data = wrap "data" true;
    });
}
