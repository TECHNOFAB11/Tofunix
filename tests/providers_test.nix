{
  pkgs,
  tflib,
  ntlib,
  ...
}: let
  cloudflare = tflib.mkOpentofuProvider {
    owner = "cloudflare";
    repo = "cloudflare";
    version = "5.15.0";
    hash = "sha256-OVmE5zPRp+kEj7zGxxVu2bcNA2gDdj4m5DgAZckQW2k=";
  };
in {
  suites."Providers" = {
    pos = __curPos;
    tests = [
      {
        name = "Cloudflare";
        type = "script";
        script = let
          opts = tflib.generateOptions [cloudflare];
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            assert "-f ${opts}/default.nix" "default.nix should exist"
            assert "-f ${opts}/cloudflare-cloudflare-5.15.0.nix" "cloudflare file should exist"
          '';
      }
    ];
  };
}
