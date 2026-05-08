# scripts

This directory contains the shell helpers used by the flake and installed commands.

## Files

- [`setup.sh`](./setup.sh): bootstrap a new repo from the template
- [`build-profiles.sh`](./build-profiles.sh): prebuild every discovered profile
- [`switch-profile.sh`](./switch-profile.sh): activate a prebuilt profile result instantly
- [`update-cabanashmul.sh`](./update-cabanashmul.sh): fetch+merge template updates, rebuild, optional switch
- [`init-vault.sh`](./init-vault.sh): copy the bundled Obsidian vault scaffold to a local path

## Setup Workflow

[`setup.sh`](./setup.sh) is exposed as:

```bash
nix run github:shmul95/cabanashmul#setup
```

It:

- clones the template
- renames `origin` to `template`
- creates `profiles/personal.nix` if missing
- creates `local.nix` if missing
- optionally creates a private GitHub `origin`

## Fast Profile Switching

[`build-profiles.sh`](./build-profiles.sh) is installed as `build-profiles`.

It:

- reads available profile names from `flake.lib.profileNamesStr`
- builds `homeConfigurations.<user>-<profile>.activationPackage`
- stores symlinks under `$XDG_DATA_HOME/cabanashmul/result-<profile>`

Run:

```bash
build-profiles
```

To build and switch in one step:

```bash
build-profiles --switch personal
```

Flags:

- `-s <profile>` / `--switch <profile>` — build all profiles, then activate the named profile with `switch-profile`

[`switch-profile.sh`](./switch-profile.sh) is installed as `switch-profile`.

Run:

```bash
switch-profile personal
```

That executes the saved activation result directly, without another Nix evaluation.

## Template Update Helper

[`update-cabanashmul.sh`](./update-cabanashmul.sh) is installed as `update-cabanashmul`.

Default behavior:

```bash
update-cabanashmul
```

This runs:

1. `git fetch template`
2. `git merge template/main`
3. `build-profiles`

Flags:

- `--no-build` — skip `build-profiles`
- `--switch <profile>` — run full update + rebuild cycle, then `switch-profile <profile>`

## Vault Bootstrap Helper

[`init-vault.sh`](./init-vault.sh) is installed as `init-vault`.

It:

- copies the bundled `vault-template/` scaffold into a local vault path
- defaults to `~/vault`
- refuses to overwrite an existing vault

Run:

```bash
init-vault
```

Or choose a different destination:

```bash
init-vault ~/Documents/vault
```
