{
  pkgs,
  lib,
  ...
}: {
  tf-pkg ? pkgs.opentofu,
  module,
  plugins ? [],
  ...
}: let
  wrapped = tf-pkg.withPlugins (_: plugins);
  source = module.config.finalPackage;
  # TODO: check if more are needed and if lockfile is really needed
  filesToCopy = [
    ".terraform"
    ".terraform.lock.hcl"
    "terraform.tfstate"
  ];
in
  (pkgs.writeShellScriptBin "tofunix" ''
    TF_TMP_DIR=$(mktemp -d)
    ln -s ${source} $TF_TMP_DIR

    # symlink all existing files and directories to the tmp dir
    for item in ${toString filesToCopy}; do
      if [ -e "$item" ]; then
        ln -s "`pwd`/$item" "$TF_TMP_DIR/$item"
      fi
    done

    function cleanup {
      # if any file does not yet exist in CWD (and thus hasn't been symlinked)
      #  we copy it back. The next run will then symlink it for better performance.
      for item in ${toString filesToCopy}; do
        if [[ -e "$TF_TMP_DIR/$item" && ! -e "$item" ]]; then
          cp -r "$TF_TMP_DIR/$item" "$item"
        fi
      done

      rm -rf "$TF_TMP_DIR"
    }

    trap cleanup EXIT

    ${lib.getExe wrapped} -chdir="$TF_TMP_DIR" "$@"
  '')
  // {
    gitlab = import ./gitlab.nix {inherit lib pkgs source wrapped;};
  }
