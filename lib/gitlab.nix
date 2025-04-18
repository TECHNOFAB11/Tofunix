{
  pkgs,
  lib,
  source,
  wrapped,
  ...
}: let
  gitlab-tofu = pkgs.stdenv.mkDerivation {
    name = "gitlab-tofu";
    src = builtins.fetchurl {
      url = "https://gitlab.com/components/opentofu/-/raw/356937d000b7839ed717562d1e6d470b946040da/src/gitlab-tofu.sh";
      sha256 = "sha256:0s3ikgdf1i24xy9bnrb80b5r85ld9hx1n846cwjj9v9ablqnl9a5";
    };
    nativeBuildInputs = [
      pkgs.makeWrapper
    ];
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      ln -s $src $out/bin/gitlab-tofu

      wrapProgram $out/bin/gitlab-tofu --prefix PATH : ${
        lib.makeBinPath [
          wrapped
          pkgs.libidn2
          pkgs.jq
        ]
      }
    '';
    meta.mainProgram = "gitlab-tofu";
  };
in
  pkgs.writeShellScriptBin "gitlab-tofunix" ''
    ln -s ${source} main.tf.json
    trap 'rm -f main.tf.json' EXIT
    ${lib.getExe gitlab-tofu} "$@"
  ''
