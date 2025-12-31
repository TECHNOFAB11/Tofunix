# Usage

There are many components to this, which can be combined or used standalone.
Generally there are two main approaches:

- let everything generate on demand
- pre-generate the provider options for versioning in git

## Setup

You only need `tofunix-lib`, import it like this:

```nix
tofunix-lib = pkgs.callPackage inputs.tofunix {};
# or
tofunix-lib = import inputs.tofunix { 
  inherit pkgs; # optional also `lib`, otherwise pkgs.lib is used
};
```

## Generating All The Things

This approach is the easiest and recommended. The options, specs, whatever are
all auto-generated for you on-demand.

Use `mkCliAio` for this.

```nix title="flake.nix"
  # perSystem
  packages.tofunix = tofunix-lib.mkCliAio {
    plugins = [
      (tofunix-lib.mkOpentofuProvider {
        owner = "bunnyway";
        repo = "bunnynet";
        version = "0.7.0";
        hash = "sha256-GvgAD+E/3potxlZJ3QF3UKB0r4I7lU/NGoV+/8R7RuU=";
      })
    ];
    moduleConfig = ./config;  # nix module, so either a path, an attrset, a function etc.
  };
```

```nix title="config/default.nix"
{ref, ...}: {
  variable."bunny_api_key" = {
    type = "string";
  };
  provider.bunnynet."default" = {
    api_key = ref.var.bunny_api_key;
  };
}
```

!!! note

    You can use `ref` to reference other resources. This basically just returns
    a string like this: `${var.bunny_api_key}`

## Pre-generating Provider Options

In this approach you will generate the provider options "manually" beforehand
and import them yourself in the final module.

First, generate the options. `result` will contain a file for each provider and
a `default.nix` which imports them all. You can copy this to your repo/wherever
you want to use it.

```nix
tofunix-lib.generateOptions [<sources here>];
```

!!! note

    You can also generate the provider options without packaging them first.
    `generateSpec` and thus also `generateOptions` supports passing strings in
    sources. See [Reference](./reference.md).

Then, in your actual module where you want to use these:

```nix
tofunix-lib.mkCli {
  plugins = [<opentofu plugins/providers>];
  module = tofunix-lib.mkModule {
    moduleConfig = ./config;
  };
};
```

## Example / Template

The repository contains a fully featured [template][template-url], including:

- Pre-Commit integration
- Nix-GitLab-CI integration
- automatic provider generation (using BunnyNet as an example)
- Setup for GitLab managed terraform state

[template-url]: https://gitlab.com/TECHNOFAB/tofunix/-/tree/main/template
