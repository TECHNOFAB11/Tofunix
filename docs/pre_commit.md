# Pre-Commit Usage

To validate your config using pre-commit use this:

```nix title="flake.nix"
pre-commit.hooks = {
  validate = {
    enable = true;
    name = "tofu-validate";
    pass_filenames = false;
    entry = 
      (pkgs.writeShellScript "tofu-validate-hook" ''
        nix run .#tofunix -- init -backend=false
        nix run .#tofunix -- validate
      '')
      .outPath;
  };
};
```
