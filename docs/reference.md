# Reference

There are multiple components to this project, each can be used on it's own or
combined to automate everything.

## `generateSpec`

Generates the terraform provider spec from a list of providers.
These can either be terraform provider packages, or strings with this format:

```
(<registry>/)<org>/<provider>@<version>
```

Registry is optional, it will default to the Opentofu registry.

## `generateOptionsForProvider`

With a provider spec (generated with the above), this generates a Nix file
containing the options for this provider (a bit like type generation).

## `generateOptions`

Combines both of the above and let's you generate multiple provider options at
once. Output is a directory, with a file for each provider with it's options and
a `default.nix` which imports all of them for easy usage.

## `mkModule`

Creates the main module which imports the provider options and the user's config.

- provides the `ref` arg, which allows you to reference any resource,
    data, variable etc. more easily.
- filters out null values
- filters out any computed or readOnly option values

## `mkCli`

Creates a wrapper script which runs all the opentofu commands in a tmp directory
with the config copied there for less impurity. Usual terraform paths like
`.terraform`, `.terraform.lock.hcl` etc. are copied back to CWD.
Also passthru's `tfjson` for the final config and `gitlab` for the
[GitLab Integration](./gitlab_integration.md).

## `mkCliAio`

Combines `mkModule` and `mkCli`, just requiring a list of providers and your
module config to automatically generate everything else and providing a usable
CLI wrapper.

## `fetchProviderSpec`

Fetches the spec/metadata of a provider (all architectures).
This metadata contains hashes for all architectures, thus we only need a single
hash for this whole derivation to make the rest reproducible and platform/arch
independent.

## `mkOpentofuProvider`

Creates an Opentofu provider, using `owner`, `repo`, `version` and `hash`.

```nix title="Example"
bunny-provider = tofunix-lib.mkOpentofuProvider {
  owner = "bunnyway";
  repo = "bunnynet";
  version = "0.7.0";
  hash = "sha256-GvgAD+E/3potxlZJ3QF3UKB0r4I7lU/NGoV+/8R7RuU=";
};
```

This provider can be used with the above functions to generate it's options.

## Utils

Contains all of terraforms functions, like `abs`.
These wrappers automatically handle `${` and `}`, so they can be chained
and the final string will just contain one `${` and `}` around it.

A complex example from [coder-templates](https://coder-templates.projects.tf):

```nix
{
  locals."git_repo_folder" = with utils; let
    split_repo = split (quot "") ref.data.coder_parameter.git_repo.value;
  in
    try [
      (element split_repo "${rb (length split_repo)} - 1")
      (quot "")
    ];
}
```
