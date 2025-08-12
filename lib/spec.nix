{
  lib,
  pkgs,
  #
  sources, # ["<org>/<provider>@<version>"]
  ...
}: let
  inherit (lib) splitString removePrefix toLower replaceStrings;

  sourcesArePackages = !builtins.isString (builtins.head sources);
  origSources = sources;
  _sources =
    if sourcesArePackages
    then (map (s: "${s.provider-source-address}@${s.version}") sources)
    else sources;

  hasRegistry = source: builtins.length (splitString "/" source) == 3;
  registry = source:
    if hasRegistry source
    then builtins.head (builtins.match "(.*)/.*/.*$" source)
    else "";
  removeRegistry = source: removePrefix ((registry source) + "/") source;
  removeVersion = source: builtins.head (builtins.match "(.*)@.*$" source);
  cleanName = source: toLower (replaceStrings ["/"] ["-"] (replaceStrings ["--"] ["-"] source));
  getProvider = source: builtins.head (builtins.match ".*/(.*)$" source);
  getVersion = source: builtins.head (builtins.match ".*@(.*)$" source);

  sourcesObj = builtins.listToAttrs (map (source: {
      name = cleanName (removeVersion (removeRegistry source));
      value = {
        source = removeVersion source;
        version = getVersion source;
      };
    })
    _sources);

  providerJson = builtins.toJSON {
    terraform.required_providers = sourcesObj;
  };

  specJson =
    pkgs.runCommand "tofunix-spec" {
      buildInputs =
        [pkgs.jq]
        ++ (
          if sourcesArePackages
          then [(pkgs.opentofu.withPlugins (_: origSources))]
          else [pkgs.opentofu]
        );
    } ''
      echo '${providerJson}' > providers.tf.json
      tofu init
      tofu providers schema -json | jq '.provider_schemas' > $out
    '';

  spec = builtins.fromJSON (builtins.readFile specJson);
  transformedSpec = builtins.listToAttrs (map (key: let
    # source = removeRegistry key;
    source = key;
    name = cleanName (removeRegistry source);
    provider = getProvider key;
  in {
    inherit name;
    value = {
      inherit name provider source;
      version = sourcesObj."${name}".version;
      spec = builtins.getAttr key spec;
    };
  }) (builtins.attrNames spec));
in
  transformedSpec
# output:
# {
#   "registry.opentofu.org/hashicorp/vault" = {
#     ...
#   };
#   ...
# }

