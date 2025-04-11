{
  lib,
  pkgs,
  fullSpec,
  ...
}: let
  provider = fullSpec.provider;
  version = fullSpec.version;
  source = fullSpec.source;
  spec = fullSpec.spec;

  convertType = typ:
    "(types.either referenceType "
    + (
      if typ == "string"
      then "types.str"
      else if typ == "number"
      then "types.number"
      else if typ == "bool"
      then "types.bool"
      else "types.unspecified"
    )
    + ")";
  # TODO: list and object support

  providerAttributes = lib.concatStrings (lib.mapAttrsToList (name: value: let
    type =
      if value.optional or false
      then "types.nullOr"
      else "";
    default =
      if value.optional or false
      then "default = null;"
      else "";
  in
    # nix
    ''
      ${name} = mkOption {
        type = ${type} ${convertType value.type};
        description = '''${value.description or ""}''';
        ${default}
      };
    '')
  spec.provider.block.attributes);

  getAttributes = resourceType: resourceName: block: isData:
    lib.concatStrings (lib.mapAttrsToList (name: value: let
      dataExtra =
        if isData
        then "data."
        else "";
    in
      # nix
      ''
        ${name} = mkOption {
          description = '''
            ${value.description or ""}
          ''';
          ${
          if value.computed or false
          then ''
            type = types.str;
            default = "\''${${dataExtra}${resourceType}.${resourceName}.${name}}";
            readOnly = true;
          ''
          else if value.optional or false
          then ''
            type = types.nullOr ${convertType value.type};
            default = null;
          ''
          else ''
            type = ${convertType value.type};
          ''
        }
        };
      '')
    block.attributes);

  genOptions = schema: isData:
    lib.concatStrings (lib.mapAttrsToList (resourceType: value:
      # nix
      ''
        ${resourceType} = mkOption {
          type = types.attrsOf (types.submodule ({name, ...}: {
            options = {
              _name = mkOption {
                internal = true;
                type = types.str;
                default = name;
              };
              ${getAttributes resourceType "\${name}" value.block isData}
            };
          }));
          description = '''
            ${value.block.description or ""}
          ''';
          default = {};
        };
      '')
    schema);

  generated =
    # nix
    ''
      {lib, options, config, ...}: let
        inherit (lib) mkOption types;
        referenceType = types.addCheck types.str (s: lib.hasPrefix "\''${" s && lib.hasSuffix "}" s);
      in {
        config.terraform.required_providers.${provider} = {
          source = "${source}";
          version = "${version}";
        };
        options.provider.${provider} = mkOption {
          type = types.nullOr (types.attrsOf (types.submodule ({name, ...}: {
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
              alias = mkOption {
                type = types.nullOr types.str;
                default = if name != "default" then name else null;
              };
              id = mkOption {
                readOnly = true;
                type = types.str;
                default = "\''${${provider}.''${name}}";
              };
              ${providerAttributes}
            };
          })));
          default = null;
          description = '''
            ${spec.provider.block.description or ""}
          ''';
        };

        options.resource = {
          ${genOptions spec.resource_schemas false}
        };

        options.data = {
          ${genOptions spec.data_source_schemas true}
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
