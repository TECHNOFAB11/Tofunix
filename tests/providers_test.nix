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
    hash = "sha256-Yvi7bgpdj9Fl48rtolxkGdW9VhiJjiG7DdZlCQJnm/w=";
  };
  sops = tflib.mkOpentofuProvider {
    owner = "carlpett";
    repo = "sops";
    version = "1.3.0";
    hash = "sha256-G60Y6hCPVI2NtE0A4wuoBVO4/Nnu882bnGhXcnPTPzU=";
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
