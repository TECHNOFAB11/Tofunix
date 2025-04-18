{pkgs, ...}: rec {
  mkTerraformProvider = {
    owner,
    repo,
    version,
    src,
    registry ? "registry.opentofu.org",
  }: let
    inherit (pkgs.go) GOARCH GOOS;
    provider-source-address = "${registry}/${owner}/${repo}";
  in
    pkgs.stdenv.mkDerivation {
      pname = "terraform-provider-${repo}";
      inherit version src;

      unpackPhase = "unzip -o $src";

      nativeBuildInputs = [pkgs.unzip];

      buildPhase = ":";

      # The upstream terraform wrapper assumes the provider filename here.
      installPhase = ''
        dir=$out/libexec/terraform-providers/${provider-source-address}/${version}/${GOOS}_${GOARCH}
        mkdir -p "$dir"
        mv terraform-* "$dir/"
      '';

      passthru = {
        inherit provider-source-address;
      };
    };

  fetchProviderSpec = {
    owner,
    repo,
    version,
    hash,
  }:
    pkgs.runCommand "opentofu-fetch-provider-spec" {
      nativeBuildInputs = with pkgs; [jq curl cacert];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
    } ''
      set -e
      mkdir -p "$out"

      url="https://registry.opentofu.org/v1/providers/${owner}/${repo}/versions"
      platforms=$(curl -fsS "$url" | jq -c ".versions[] | select(.version == \"${version}\") | .platforms[]")
      echo "$platforms" | while read -r p; do
        os=$(echo "$p" | jq -r .os)
        arch=$(echo "$p" | jq -r .arch)
        echo "Downloading $os/$arch spec"
        curl -fsS "https://registry.opentofu.org/v1/providers/${owner}/${repo}/${version}/download/$os/$arch" -o "$out/''${os}_''${arch}.json"
      done
    '';

  mkOpentofuProvider = {
    owner,
    repo,
    version,
    os ? pkgs.go.GOOS,
    arch ? pkgs.go.GOARCH,
    hash,
  }: let
    specs = fetchProviderSpec {inherit owner repo version hash;};
    spec = builtins.fromJSON (builtins.readFile "${specs}/${os}_${arch}.json");
  in
    mkTerraformProvider {
      inherit version owner repo;
      src = pkgs.fetchurl {
        url = spec.download_url;
        sha256 = spec.shasum;
      };
    };
}
