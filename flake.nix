{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ren.url = "gitlab:rensa-nix/core/v0.1.1?dir=lib";
  };

  outputs = {
    ren,
    self,
    ...
  } @ inputs:
    ren.buildWith
    {
      inherit inputs;
      cellsFrom = ./nix;
      transformInputs = system: i:
        i
        // {
          pkgs = import i.nixpkgs {inherit system;};
        };
      cellBlocks = with ren.blocks; [
        (simple "devShells")
        (simple "ci")
        (simple "tests")
        (simple "docs")
        (simple "soonix")
      ];
    }
    {
      packages = ren.select self [
        ["repo" "ci" "packages"]
        ["repo" "tests"]
        ["repo" "docs"]
        ["repo" "soonix" "packages"]
      ];
      templates."default" = {
        path = ./template;
        description = "Fully featured template/example";
      };
    };
}
