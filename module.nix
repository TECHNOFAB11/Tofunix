{
  pkgs,
  lib,
  tf-pkg ? pkgs.opentofu,
  plugins ? [],
  ...
}: let
  wrapped = tf-pkg.withPlugins (_: plugins);
  providers-tf = pkgs.writeTextDir "share/providers.tf.json" (builtins.toJSON {
    terraform.required_providers = builtins.listToAttrs (map (p: {
        name = lib.removePrefix "terraform-provider-" p.pname;
        value.source = p.provider-source-address;
      })
      plugins);
  });
  sources = pkgs.symlinkJoin {
    name = "tofunix-sources";
    paths = [
      providers-tf
      # TODO: generate terraform config here (main.tf.json)
    ];
  };
  # TODO: check if more are needed and if lockfile is really needed
  filesToCopy = [
    ".terraform"
    ".terraform.lock.hcl"
    "terraform.tfstate"
  ];
in
  pkgs.writeShellScriptBin "tofunix" ''
    TF_TMP_DIR=$(mktemp -d)
    ln -s ${sources}/share/* $TF_TMP_DIR

    # symlink all existing files and directories to the tmp dir
    for item in ${toString filesToCopy}; do
      if [ -e "$item" ]; then
        ln -s "`pwd`/$item" "$TF_TMP_DIR/$item"
      fi
    done

    ${lib.getExe wrapped} -chdir="$TF_TMP_DIR" "$@"

    # if any file does not yet exist in CWD (and thus hasn't been symlinked)
    #  we copy it back. The next run will then symlink it for better performance.
    for item in ${toString filesToCopy}; do
      if [[ -e "$TF_TMP_DIR/$item" && ! -e "$item" ]]; then
        cp -r "$TF_TMP_DIR/$item" "$item"
      fi
    done

    rm -rf "$TF_TMP_DIR"
  ''
