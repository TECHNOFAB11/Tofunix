{
  lib,
  pkgs,
  fullSpec,
  ...
}: let
  inherit (lib) concatStrings mapAttrsToList;
  inherit (fullSpec) provider version source spec;

  cleanDescription = val:
    builtins.replaceStrings ["\${"] ["''\${"] (val.description or "");

  genObjectOptions = typ:
    concatStrings (mapAttrsToList (name: value: ''
        ${name} = mkUnsetOption {type = ${convertType value};};
      '')
      typ);
  typeMap = {
    "string" = "types.str";
    "number" = "types.number";
    "bool" = "types.bool";
    "object" = "types.submodule";
    "map" = "types.attrsOf";
    "list" = "types.listOf";
    "set" = "types.listOf";
    "dynamic" = "types.unspecified";
  };
  convertTypeInner = typ:
    if (builtins.isList typ)
    then
      # for nested stuff like attrsOf we need to repeat the "either referenceType" stuff
      # so references work in maps aswell for example
      if builtins.length typ > 1
      then let
        outerType = convertTypeInner (builtins.head typ);
        innerType =
          # if outer is a submodule we cannot add "types.either" between it and the suboptions
          if outerType != "types.submodule"
          then convertType (builtins.tail typ)
          else convertTypeInner (builtins.tail typ);
      in "${outerType} ${innerType}"
      else convertTypeInner (builtins.head typ)
    else if (builtins.isAttrs typ)
    then "{options = {${genObjectOptions typ}};}"
    else typeMap.${typ} 
      or (builtins.trace "[tofunix] warning, found unknown type: ${typ}" "types.unspecified");
  convertType = typ:
    builtins.addErrorContext "[tofunix] while converting type ${builtins.toJSON typ}"
    "(types.either referenceType (${convertTypeInner typ}))";
  convertNestedType = typ:
  # TODO: no idea what other `nesting_mode`s exist, the cloudflare provider only uses `single` for example.
  # Maybe list and maps also exist? Then we just have to prepend attrsOf or listOf maybe?
    builtins.addErrorContext "[tofunix] while converting nested type ${builtins.toJSON typ}"
    ''
      types.submodule {
        options = {
          ${mkAttributes typ.attributes or {}}
        };
      }
    '';

  mkAttributes = src:
    concatStrings (mapAttrsToList (name: value: let
      mkOptName =
        if value.optional or value.computed or false
        then "mkUnsetOption"
        else "mkOption";
    in
      builtins.addErrorContext "[tofunix] while making attributes for ${name} (value: ${builtins.toJSON value})"
      # nix
      ''
        "${name}" = ${mkOptName} {
            type = ${
          if value ? nested_type
          then convertNestedType value.nested_type
          else convertType value.type
        };
          description = '''${cleanDescription value} ''';
        };
      '')
    src);
  providerAttributes = mkAttributes spec.provider.block.attributes or {};

  getBlocks = resourceType: resourceName: block: isData:
    builtins.addErrorContext "[tofunix] while getting blocks of resource type '${resourceType}'" (
      concatStrings (mapAttrsToList (name: value:
        builtins.addErrorContext "[tofunix] while generating option for '${name}' (value: ${builtins.toJSON value})"
        # nix
        ''
          "${name}" = mkUnsetOption {
            type = let mod = (types.submodule {
              options = {
                ${getAttributes resourceType resourceName value.block isData}
                ${getBlocks resourceType resourceName value.block isData}
              };
            }); in types.either mod (types.listOf mod);
            description = '''${cleanDescription value} ''';
          };
        '') (block.block_types or {}))
    );

  getAttributes = resourceType: resourceName: block: isData:
    builtins.addErrorContext "[tofunix] while getting attributes of resource type '${resourceType}'" (
      concatStrings (mapAttrsToList (name: value: let
        mkOptName =
          if value.optional or value.computed or false
          then "mkUnsetOption"
          else "mkOption";
      in
        builtins.addErrorContext "[tofunix] while generating option for '${name}' (value: ${builtins.toJSON value})"
        # nix
        ''
          "${name}" = ${mkOptName} {
            type = ${
            if value ? nested_type
            then convertNestedType value.nested_type
            else convertType value.type
          };
            description = '''${cleanDescription value} ''';
            apply = val: if val ? __toString then builtins.toString val else val;
          };
        '')
      block.attributes or {})
    );

  genOptions = schema: isData:
    concatStrings (mapAttrsToList (resourceType: value:
      builtins.addErrorContext "[tofunix] while generating options for '${resourceType}' (value: ${builtins.toJSON value})"
      # nix
      ''
        "${resourceType}" = mkUnsetOption {
          type = types.attrsOf (types.submodule ({name, ...}: {
            _file = "generated ${provider} provider";
            options = {
              _name = mkOption {
                internal = true;
                type = types.str;
                default = name;
              };
              count = mkUnsetOption {
                type = types.either referenceType types.int;
                description = '''
                  Terraform count, used to create multiple instances of this resource/data.
                ''';
              };
              ${getAttributes resourceType "\${name}" value.block isData}
              ${getBlocks resourceType "\${name}" value.block isData}
            };
          }));
          description = '''${cleanDescription value.block} ''';
        };
      '')
    schema);

  generated =
    builtins.addErrorContext "[tofunix] while generating main nix file for provider ${provider}"
    # nix
    ''
      {lib, options, config, ...}: let
        inherit (lib) mkOption mkOptionType types isType literalExpression hasPrefix hasSuffix;
        unsetType = mkOptionType {
          name = "unset";
          description = "unset";
          descriptionClass = "noun";
          check = isType "unset";
        };
        unset = {
          _type = "unset";
        };
        unsetOr = typ:
          (types.either unsetType typ)
          // {
            inherit (typ) description getSubOptions;
          };
        mkUnsetOption = args:
          mkOption args
          // {
            type = unsetOr args.type;
            default = args.default or unset;
            defaultText = literalExpression "unset";
          };
        referenceType = mkOptionType {
          name = "reference";
          description = "reference";
          descriptionClass = "noun";
          check = val: (builtins.isString val || val ? __toString) && hasPrefix "\''${" (builtins.toString val) && hasSuffix "}" (builtins.toString val);
        };
      in rec {
        _file = "generated ${provider} provider";
        config.terraform.required_providers.${provider} = {
          source = "${source}";
          version = "${version}";
        };
        config.generated.provider."${provider}" = mkUnsetOption {
          type = types.attrsOf (types.submodule ({name, ...}: {
            _file = "generated ${provider} provider";
            options = {
              _name = mkOption {
                internal = true;
                type = types.str;
                default = name;
              };
              _version = mkOption {
                internal = true;
                type = types.str;
                default = "${version}";
              };
              alias = mkUnsetOption {
                type = types.str;
                default = if name != "default" then name else unset;
                description = '''
                  Alias for this terraform provider. Automatically set to "''${name}".
                ''';
              };
              id = mkOption {
                readOnly = true;
                type = types.str;
                default = "\''${${provider}.''${name}}";
                defaultText = literalExpression "\"\''${${provider}.''${name}}\"";
                description = '''
                  ID of provider, read only. Only returns a terraform reference string.
                ''';
              };
              ${providerAttributes}
            };
          }));
          description = '''${cleanDescription spec.provider.block}''';
        };

        # required for looking up the suboptions
        config.generated = {
          resource = {
            ${genOptions spec.resource_schemas false}
          };
          data = {
            ${genOptions spec.data_source_schemas true}
          };
        };
        # hacky unfortunately
        options = {
          inherit (config.generated) resource data provider;
        };
      }
    '';
in
  pkgs.runCommand "tofunix-${provider}-${version}-gen.nix"
  {
    buildInputs = [pkgs.nixpkgs-fmt];
  } ''
    cat << 'GENERATED' > $out
    ${generated}
    GENERATED

    nixpkgs-fmt $out
  ''
