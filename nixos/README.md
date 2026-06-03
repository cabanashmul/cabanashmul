# nixos

This directory adds the NixOS layer on top of the existing `public/`, `private/`, and `secrets/` Home Manager structure.

The current starter exports a single host:

- `flake.nixosConfigurations.cabanashmul`

That host is meant to be rebuilt with:

```bash
sudo nixos-rebuild switch --flake .#cabanashmul
```

## What It Loads

[`flake.nix`](../flake.nix) imports:

1. [`_options.nix`](./_options.nix)
2. [`_builder.nix`](./_builder.nix)
3. every other `*.nix` file in this directory

`_options.nix` defines the NixOS-specific `flake.cabanashmul.nixos` settings.

`_builder.nix` turns that config into `flake.nixosConfigurations.cabanashmul` and wires in Home Manager so the system rebuild updates both NixOS and the user environment together.

## What The NixOS Layer Does

- sets the hostname to `cabanashmul`
- creates the primary local user
- enables Home Manager inside the NixOS system
- reuses every module from [`public/`](../public/), including private additions when present
- leaves room for host-specific NixOS modules under this directory

## How To Add More NixOS Settings

Add another file like `nixos/desktop.nix`:

```nix
{ ... }: {
  flake.cabanashmul.nixosModules.desktop = { lib, pkgs, ... }: {
    # NixOS config here
  };
}
```

Because [`flake.nix`](../flake.nix) imports the whole directory, the module is picked up automatically.

## Hardware Configuration

If you are turning this into a real machine config, add a generated `nixos/hardware-configuration.nix` next to this README and the builder will import it automatically.

If you want to keep that file out of the repo, you can also generate it locally and copy the relevant settings into one of the NixOS modules here.
