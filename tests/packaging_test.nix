{
  tflib,
  ntlib,
  pkgs,
  ...
}: {
  suites."Packaging" = {
    pos = __curPos;
    tests = [
      {
        name = "mkTerraformProvider packages a provider correctly";
        type = "script";
        script = let
          provider = tflib.mkTerraformProvider {
            owner = "hashicorp";
            repo = "null";
            version = "3.2.2";
            src = pkgs.fetchurl {
              url = "https://releases.hashicorp.com/terraform-provider-null/3.2.2/terraform-provider-null_3.2.2_linux_amd64.zip";
              hash = "sha256-Mkiq5qIZjz7IOUIY0FvV5Cvln0Ojp8C3HGbsDfCLaec=";
            };
          };
          # GOOS and GOARCH are determined by pkgs.go
          inherit (pkgs.go) GOOS GOARCH;
          provider_dir = "${provider}/libexec/terraform-providers/registry.opentofu.org/hashicorp/null/3.2.2/${GOOS}_${GOARCH}";
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-d ${provider_dir}" "Provider directory should exist at the correct path"
            # check for actual binary inside
            assert "-f ${provider_dir}/terraform-provider-null_v3.2.2_x5" "Provider binary should be in the directory"
          '';
      }
    ];
  };
}
