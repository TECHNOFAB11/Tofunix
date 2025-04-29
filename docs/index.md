# Tofunix

Writing Terraform configurations using Nix, validated by the NixOS/nixpkgs module system.
Inspired by [Terranix](https://terranix.org) but stricter and mostly for use with [OpenTofu](https://opentofu.org).

## Features

- **Correctness**: Generator to create Nix modules for providers, helps finding
    issues early <br> (a bit like type generation)
- **Reproducible**: Same input results in the same output, thanks to Nix
- **Developer Experience**: Nix is arguably better than HCL (not by a lot to be fair ;P)
