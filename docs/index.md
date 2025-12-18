# Tofunix

Writing Terraform configurations using Nix, validated by the NixOS/nixpkgs module system.
Inspired by [Terranix](https://terranix.org) but stricter and mostly for use with [OpenTofu](https://opentofu.org).

## What is Tofunix?

Tofunix bridges the Nix and Terraform/Opentofu ecosystems by allowing you to define your infrastructure as Nix expressions (everything, not just NixOS and friends). It provides:

- **Type-safe resource definitions & correctness** using Nix's module system & generators
- **Reproducible environments** with locked dependencies
- **Developer Experience**: Nix is arguably better and more flexible than HCL

## Comparison to Terranix

Terranix is mostly untyped (in this case "typed" refers to being checked by the NixOS module system (not specific to NixOS though!)).
This means that Terranix is a bit more than `builtins.toJSON {<your config>}`, but that's basically it.
There are some modules (two at the time of writing), [one example being cloudflare](https://github.com/terranix/terranix/blob/3b5947a48da5694094b301a3b1ef7b22ec8b19fc/modules/provider/cloudflare.nix).

Tofunix on the other hand generates options for all your providers on the fly or beforehand (however you choose).
This means that you get validation from Nix and could potentially even receive LSP support from NixD for example, when you
configure it with your Tofunix options (from the Tofunix module). It also integrates more easily with other projects like [Nix-GitLab-CI](https://nix-gitlab-ci.projects.tf) for running in CI etc.

!!! warning

    Using NixD is untested, might work, might not work, that stuff is in general a bit tricky since Nix
    is not really made for that, so the LSPs have a really hard time :D

Also, Tofunix contains helpers which allow you to easily use Terraform/Opentofu functions, see [Reference](./reference.md#utils).
