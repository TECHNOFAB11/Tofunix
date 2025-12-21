# Debugging

To help with debugging, Tofunix uses Nix's `builtins.addErrorContext` to add context
about where an error is happening in the generation.

Use the following command to get just these logs from Tofunix and please include that (or the whole stacktrace) in any issues or bug reports :)

```sh
nix ... --show-trace 2> >(grep "… \[tofunix\]")
```

So for example:

```sh
nix run .#tofunix --show-trace 2> >(grep "… \[tofunix\]")
```
