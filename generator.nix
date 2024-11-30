{
  lib,
  pkgs,
  version,
  source,
  ...
}: let
  provider = builtins.head (builtins.match ".*/([^/]+)$" source);
  name = lib.toLower (lib.replaceStrings ["/"] ["-"] (lib.replaceStrings ["--"] ["-"] source));
  providerJson = builtins.toJSON {
    terraform.required_providers."${name}" = {
      inherit source version;
    };
  };
  specJson =
    pkgs.runCommand "tofunix-${name}-spec" {
      buildInputs = [pkgs.opentofu pkgs.jq];
    } ''
      echo '${providerJson}' > providers.tf.json
      tofu init
      tofu providers schema -json | jq '.provider_schemas[] | {provider, resource_schemas, data_source_schemas}' > $out
    '';
  spec = builtins.fromJSON (builtins.readFile specJson);

  convertType = typ:
    if typ == "string"
    then "types.str"
    else if typ == "number"
    then "types.number"
    else if typ == "bool"
    then "types.bool"
    else "types.unspecified";
  # TODO: list and object support

  providerAttributes = lib.concatStrings (lib.mapAttrsToList (name: value:
    # nix
    ''
      ${name} = mkOption {
        type = ${
        if value.optional
        then "types.nullOr"
        else ""
      } ${convertType value.type};
        description = '''${value.description}''';
        ${
        if value.optional
        then "default = null;"
        else ""
      }
      };
    '')
  spec.provider.block.attributes);

  getAttributes = resourceType: resourceName: block:
    lib.concatStrings (lib.mapAttrsToList (name: value:
      # nix
      ''
        ${name} = mkOption {
          description = '''${value.description or ""}''';
          ${
          if value.computed or false
          then ''
            type = types.str;
            default = "${resourceType}.${resourceName}.${name}";
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

  genOptions = schema:
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
              ${getAttributes resourceType "\${name}" value.block}
            };
          }));
          description = '''${value.block.description}''';
          default = {};
        };
      '')
    schema);

  # TODO: create wrapper like string with context, so that variables can be passed around
  #  and wrapped with functions and at the end still add their ${ and }

  generated =
    # nix
    ''
      {lib, options, config, ...}: let
        inherit (lib) mkOption types;
      in {
        options.providers.${provider} = mkOption {
          type = types.nullOr (types.attrsOf (types.submodule ({name, ...}: {
            options = {
              _name = mkOption {
                internal = true;
                type = types.str;
                default = name;
              };
              alias = mkOption {
                type = types.nullOr types.str;
                default = if name != "default" then name else null;
              };
              id = mkOption {
                readOnly = true;
                type = types.str;
                default = "${provider}.''${name}";
              };
              ${providerAttributes}
            };
          })));
          default = null;
          description = '''${spec.provider.block.description}''';
        };

        options.resource = {
          ${genOptions spec.resource_schemas}
        };

        options.data = {
          ${genOptions spec.data_source_schemas}
        };
      }
    '';
in
  pkgs.runCommand "tofunix-${name}-gen.nix"
  {
    buildInputs = [pkgs.nixpkgs-fmt];
  } ''
    cat << 'GENERATED' > $out
    ${generated}
    GENERATED

    nixpkgs-fmt $out
  ''
