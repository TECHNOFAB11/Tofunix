# Tofunix

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)
[![pipeline status](https://gitlab.com/TECHNOFAB/tofunix/badges/main/pipeline.svg)](https://gitlab.com/TECHNOFAB/tofunix/-/commits/main)
![License: MIT](https://img.shields.io/gitlab/license/technofab/tofunix)
[![Latest Release](https://gitlab.com/TECHNOFAB/tofunix/-/badges/release.svg)](https://gitlab.com/TECHNOFAB/tofunix/-/releases)
[![Support me](https://img.shields.io/badge/Support-me-yellow)](https://tec.tf/#support)
[![Docs](https://img.shields.io/badge/Read-Docs-yellow)](https://tofunix.projects.tf)

Writing Terraform configurations using Nix, validated by the NixOS/nixpkgs module system.
Inspired by [Terranix](https://terranix.org) but stricter and mostly for use with [OpenTofu](https://opentofu.org).

## What is Tofunix?

Tofunix bridges the Nix and Terraform/Opentofu ecosystems by allowing you to define your infrastructure as Nix expressions (everything, not just NixOS and friends). It provides:

- **Type-safe resource definitions & correctness** using Nix's module system & generators
- **Reproducible environments** with locked dependencies
- **Developer Experience**: Nix is arguably better and more flexible than HCL

## Quick Start

### 1. Define your configuration

Create a `my-infra.nix` file:

```nix title="my-infra.nix"
{ref, ...}: {
  variable."bunny_api_key" = {
    type = "string";
  };
  provider.bunnynet."default" = {
    api_key = ref.var.bunny_api_key;
  };
}
```

### 2. Run with Nix

```nix title="flake.nix"
{
  inputs.tofunix.url = "gitlab:TECHNOFAB/tofunix?dir=lib";
  # perSystem
  # tofunix_lib = inputs.tofunix.lib { inherit pkgs lib; };
  packages.tofunix = tofunix-lib.mkCliAio {
    plugins = [
      (tofunix-lib.mkOpentofuProvider {
        owner = "bunnyway";
        repo = "bunnynet";
        version = "0.7.0";
        hash = "sha256-GvgAD+E/3potxlZJ3QF3UKB0r4I7lU/NGoV+/8R7RuU=";
      })
    ];
    moduleConfig = ./my-infra.nix;  # nix module, so either a path, an attrset, a function etc.
  };
}
```

```bash
nix run .#tofunix -- apply # , validate, etc.
```

## Documentation

See the [docs](https://tofunix.projects.tf).
