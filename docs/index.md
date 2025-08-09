# Tofunix

Writing Terraform configurations using Nix, validated by the NixOS/nixpkgs module system.
Inspired by [Terranix](https://terranix.org) but stricter and mostly for use with [OpenTofu](https://opentofu.org).

## What is Tofunix?

Tofunix bridges the Nix and Terraform/Opentofu ecosystems by allowing you to define your infrastructure as Nix expressions (everything, not just NixOS and friends). It provides:

- **Type-safe resource definitions & correctness** using Nix's module system & generators
- **Reproducible environments** with locked dependencies
- **Developer Experience**: Nix is arguably better and more flexible than HCL
