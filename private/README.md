# private

This directory is for modules that only belong in your private fork.

It is loaded the same way as [`public/`](../public/): every `*.nix` file here is auto-imported by [`flake.nix`](../flake.nix) when the directory exists.

Typical uses:

- wiring private `git+ssh` flake inputs into Home Manager modules
- enabling repos or tools that should not appear in the public template
- machine-specific or employer-specific modules

Example private module:

```nix
{ inputs, ... }: {
  flake.cabanashmul.homeModules.shmulcode = { ... }: {
    imports = [ inputs.shmulcode.homeManagerModules.default ];

    programs.shmulcode.enable = true;
  };
}
```

Example private flake input in [`flake.nix`](../flake.nix):

```nix
shmulcode = {
  url = "git+ssh://git@github.com/shmul95/shmulcode";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Private inputs must be added directly to the static `inputs` attrset in `flake.nix`. [`private-inputs.example.nix`](../private-inputs.example.nix) documents the pattern.

Official flake input references:

- https://nix.dev/concepts/flakes.html
- https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html
