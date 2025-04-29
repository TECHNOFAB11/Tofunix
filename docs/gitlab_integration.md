# GitLab Integration

## General

Tofunix supports GitLab managed Terraform state OOTB.
It's based on the [`gitlab-terraform`][gitlab-terraform] script to automatically configure everything
for you in CI/CD pipelines.

If you're using `mkCliAio` like this:

```nix
packages = {
  tofunix = tofunix-lib.mkCliAio {
    plugins = [...];
    moduleConfig = {ref, ...}: {
      # ...
    };
  };
}
```

Then in CI you can simply use `.#tofunix.gitlab` to run your commands.
This will automatically set everything up etc.

```sh title="Example"
nix run .#tofunix.gitlab -- init
```

!!! note
    Do note that the Gitlab script just symlinks the .tf.json to your CWD and deletes it on exit.
    The main Tofunix script is a bit more involved to prevent other local files from influencing
    the output.
    Thus make sure no other `.tf` or `.tf.json` files exist in the CI CWD / run
    it from a tmp dir.

## Nix GitLab CI Integration

Because the above simply provides a Terraform/Opentofu wrapper built for GitLab
CI, it can also easily be used with [Nix GitLab CI](https://gitlab.com/TECHNOFAB/nix-gitlab-ci).

For this, simply specify the above package (either with `rec` and
`packages.tofunix.gitlab` or `config.packages.tofunix.gitlab` for example) in
`nix.deps` of a job. This automatically makes `gitlab-tofunix` available in
your job. Running any `gitlab-tofunix` command like `init` will use the
terraform config from the flake.

```nix title="flake.nix"
# perSystem
rec {
  packages.tofunix = tofunix-lib.mkCliAio ...;
  ci.jobs."validate" = {
    nix.deps = [packages.tofunix.gitlab];
    script = [
      "gitlab-tofunix validate"
    ];
  };
}
```

[gitlab-terraform]: https://gitlab.com/gitlab-org/terraform-images/-/blob/master/src/bin/gitlab-terraform.sh
