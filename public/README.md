# public

This directory contains the tracked Home Manager modules that define the public base of `cabanashmul`.

If you want to understand what the starter enables by default, start here.

## How It Loads

[`flake.nix`](../flake.nix) imports:

1. [`_options.nix`](./_options.nix)
2. [`_builder.nix`](./_builder.nix)
3. every other `*.nix` file in this directory

`_options.nix` defines the `flake.cabanashmul` option schema.

`_builder.nix` turns the merged `flake.cabanashmul` config into Home Manager configurations and chooses the active profile from:

1. `CABANASHMUL_PROFILE`
2. `flake.cabanashmul.defaultProfile`
3. `personal`, if that profile exists
4. the only available profile, if there is exactly one

## What The Public Modules Do

- [`core.nix`](./core.nix): enables `git` and optional `ssh` config from the active profile
- [`direnv.nix`](./direnv.nix): enables `direnv` and `nix-direnv`
- [`kitty.nix`](./kitty.nix): enables `kitty` only when `context = "desktop"`
- [`packages.nix`](./packages.nix): installs helper commands and desktop packages
- [`get-shmul-done.nix`](./get-shmul-done.nix): imports `get-shmul-done` and enables `programs.gsd`
- [`setup.nix`](./setup.nix): exposes the `nix run ...#setup` bootstrap app
- [`shmulvim.nix`](./shmulvim.nix): enables `shmulvim`
- [`tshmux.nix`](./tshmux.nix): enables and configures `tshmux`
- [`zshmul.nix`](./zshmul.nix): enables and configures `zshmul`

## How To Add A Public Module

Add a new file like `public/my-module.nix`:

```nix
{ ... }: {
  flake.cabanashmul.homeModules.my-module = { ... }: {
    # Home Manager config here
  };
}
```

Because `flake.nix` imports the whole directory, the module is picked up automatically.

Use `public/` for defaults that belong in the public starter. Use [`private/`](../private/README.md) for private-fork modules.

## How To Remove Something

The simplest way to disable a default module in your fork is to delete its file from `public/`.

Examples:

- delete [`get-shmul-done.nix`](./get-shmul-done.nix) if you do not want `get-shmul-done`
- delete [`shmulvim.nix`](./shmulvim.nix) if you do not want `shmulvim`
- edit or replace [`packages.nix`](./packages.nix) if you want a different package set
- edit [`zshmul.nix`](./zshmul.nix) or [`tshmux.nix`](./tshmux.nix) to change their defaults
