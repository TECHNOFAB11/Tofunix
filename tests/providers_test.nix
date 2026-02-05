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
  sops = tflib.mkOpentofuProvider {
    owner = "carlpett";
    repo = "sops";
    version = "1.3.0";
    hash = "sha256-fs+RFt8afdzv8wyMUl+zxgGSxKOdGEerL3k3TTjio/g=";
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
      {
        # only has data sources
        name = "SOPS";
        type = "script";
        script = let
          opts = tflib.generateOptions [sops];
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            assert "-f ${opts}/default.nix" "default.nix should exist"
            assert "-f ${opts}/carlpett-sops-1.3.0.nix" "sops file should exist"
          '';
      }
    ];
  };
}
