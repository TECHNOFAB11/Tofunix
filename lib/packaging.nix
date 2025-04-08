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
    sha256,
    os ? "linux",
    arch ? "amd64",
  }:
    builtins.fetchurl {
      url = "https://registry.opentofu.org/v1/providers/${owner}/${repo}/${version}/download/${os}/${arch}";
      inherit sha256;
    };

  mkOpentofuProvider = {
    owner,
    repo,
    version,
    sha256,
  }: let
    spec = builtins.fromJSON (builtins.readFile (fetchProviderSpec {inherit owner repo version sha256;}));
  in
    mkTerraformProvider {
      inherit version owner repo;
      src = pkgs.fetchurl {
        url = spec.download_url;
        sha256 = spec.shasum;
      };
    };
}
