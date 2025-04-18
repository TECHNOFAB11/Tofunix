{
  pkgs,
  lib,
  source,
  wrapped,
  ...
}: let
  gitlab-tofu = pkgs.stdenv.mkDerivation {
    name = "gitlab-tofu";
    src = pkgs.fetchurl {
      url = "https://gitlab.com/components/opentofu/-/raw/356937d000b7839ed717562d1e6d470b946040da/src/gitlab-tofu.sh";
      sha256 = "sha256-NQCML0ElSzCt4gHfIxDmjduZrPMZ6VKaM0T0QV5N+II=";
      executable = true;
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
          pkgs.curl
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
