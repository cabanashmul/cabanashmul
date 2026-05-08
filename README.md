<div align="center">

# cabanashmul

**A dendritic Home Manager starter flake.**
*Drop a `.nix` file in a folder, and it loads.*

[![Nix Flake](https://img.shields.io/badge/Nix-Flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![Home Manager](https://img.shields.io/badge/Home%20Manager-supported-7EB26D)](https://github.com/nix-community/home-manager)
[![Built with Nix](https://img.shields.io/badge/Built%20with-Nix-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![dendritic](https://img.shields.io/badge/pattern-dendritic-8957E5)](https://github.com/vic/import-tree)

[Get Started](#get-started) · [Architecture](#architecture) · [Fast Profile Switching](#fast-profile-switching) · [AI runtimes via get-shmul-done](#ai-runtimes-via-get-shmul-done) · [Troubleshooting](#troubleshooting)

</div>

---

Most Home Manager repos grow into a tangled `home.nix` that mixes machine setup, identity, and secrets. `cabanashmul` separates those concerns into four independent layers — a public base, an optional private fork, per-identity profiles, and optional secrets — and auto-imports each one. There is no central file to edit.

## Highlights

- **Dendritic layout** — every `*.nix` file in `public/`, `private/`, and `profiles/` is auto-imported via [`import-tree`](https://github.com/vic/import-tree). Adding a module is creating a file.
- **Public / private split** — track shared defaults publicly, layer private modules and `git+ssh` flake inputs on top without forking the public base.
- **Profiles as identity** — switch Git and SSH identity per profile (`personal`, `work`, ...) with per-user flake outputs like `home-manager switch --flake .#"$USER"-work`.
- **One-command bootstrap** — `nix run github:shmul95/cabanashmul#setup` creates `profiles/personal.nix` and `local.nix` for you.
- **Instant profile switches** — prebuild every profile with `build-profiles`, then jump between them with `switch-profile work` (no flake re-evaluation).
- **Optional agenix** — secrets, private modules, and extra profiles are all opt-in. The starter works with just `profiles/personal.nix`.

## Architecture

```
cabanashmul/
├── public/        # tracked base modules (auto-imported)
│   ├── _options.nix    # flake.cabanashmul option schema
│   ├── _builder.nix    # builds homeConfigurations, picks active profile
│   ├── core.nix        # git + ssh wiring from the active profile
│   ├── zshmul.nix · tshmux.nix · shmulvim.nix · kitty.nix · ...
│   └── packages.nix
├── private/       # optional, .gitignored: private modules + SSH-gated inputs
├── profiles/      # per-identity Git/SSH settings (personal.nix, work.nix, ...)
├── secrets/       # optional agenix recipient map
├── scripts/       # setup, build-profiles, switch-profile helpers
├── local.nix      # machine-local defaults (context, defaultProfile)
└── flake.nix
```

The flake exposes one Home Manager configuration per profile (`.#"$USER"-personal`, `.#"$USER"-work`, ...) plus a default `.#"$USER"` alias that resolves via `flake.cabanashmul.defaultProfile` → `personal` → the only profile. Because Home Manager picks `homeConfigurations."$USER"` automatically when no attribute is given, **`home-manager switch --impure --flake .` is the everyday command** — it builds your default profile. Use the explicit `.#"$USER"-<profile>` form only when switching to a non-default profile. (`CABANASHMUL_PROFILE` is still honored for backward compatibility but is deprecated.)

## Get Started

This walks you from zero to a working setup in five steps. Skim if you're a Nix veteran; read every step if you're not. There's a one-block [Quick Start](#quick-start-for-nix-veterans) at the end of this section for skimmers.

### What is Nix?

Nix is a package manager that installs software in `/nix/store` without touching your system. It keeps installs reproducible, removable, and isolated from the rest of your machine.

### What is Home Manager?

Home Manager uses Nix to manage your user-level dotfiles and packages declaratively. Instead of editing `~/.zshrc` by hand, you describe what you want in a `.nix` file and rebuild.

### What is cabanashmul?

cabanashmul is a starter template that gives Home Manager a sensible folder structure so you don't have to design one yourself. You don't need to learn the Nix language to use this. You'll mostly be copying files and editing values.

### Prerequisites

- **Nix with flakes enabled.** If you don't have Nix yet, see [Install Nix](#1-install-nix) below.
- **git** installed (the setup app uses it).
- A few minutes, and a willingness to **log out and back in** at the end if you want `zsh` as your login shell.

### 1. Install Nix

Skip this step if `nix --version` already prints something on your machine and your installer enabled flakes.

The Determinate Systems installer is the easiest path — it enables flakes by default and uninstalls cleanly:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Open a new terminal so `nix` is on your `PATH`.

If you used another installer and `nix run` complains about flakes, add this to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### 2. Bootstrap cabanashmul

From any directory, run:

```bash
nix run github:shmul95/cabanashmul#setup
cd cabanashmul
```

The setup app:

- Clones the template into `./cabanashmul/` (pass a different name to use a different folder: `nix run ...#setup my-config`).
- Renames the `origin` remote to `template` so `git fetch template && git merge template/main` keeps you up to date.
- Creates `profiles/personal.nix` and `local.nix` inside the clone.
- Optionally offers to create a private GitHub repo and set it as a new `origin` (requires the `gh` CLI; answer `n` if you don't want this).

### 3. Configure files

Edit `profiles/personal.nix` with your real name and email in the `git.settings.user` block before continuing. If you want machine-local settings, put them in `local.nix`.

### 4. Rebuild or switch

Edit any `.nix` file in your config, then run:

```bash
nix shell home-manager#home-manager           # adds home-manager to this terminal only
home-manager switch --impure --flake . -b backup
```

About those flags:

- **`--impure`** lets the builder read `$USER` and `$HOME` from your environment. It's required, not a code smell.
- **`-b backup`** renames any pre-existing dotfile (like an existing `~/.zshrc`) to `<file>.backup` instead of refusing to switch. Only needed on the first run if you already had dotfiles in place.
- **`--flake .`** picks the home configuration named after your username — by default, your `personal` profile. Switching to another profile uses an explicit name; see [Architecture](#architecture).

Open a new terminal. You should see:

- A Typewritten-style single-line zsh prompt.
- `git config user.email` matching what you put in `profiles/personal.nix`.
- `tmux` and `nvim` available and configured (run them and check).

If something doesn't match, jump to [Troubleshooting](#troubleshooting).

### 5. Update from the template

If there is an update in the template repo and want to be up to date

```bash
git fetch template
git merge template/main
```

or if your on later version you can

```bash
update-cabanashmul # optionnaly use flag --switch <profile> to directly switch
```

(`-b backup` is no longer needed — your old dotfiles were already moved aside on the first run.) For near-instant switches between multiple profiles, see [Fast Profile Switching](#fast-profile-switching).

To roll back a bad change: `home-manager generations`, then run the `activate` script of the previous one.

The [Home Manager manual](https://nix-community.github.io/home-manager/) and [nix.dev](https://nix.dev/) are the canonical references when you want to go deeper.

### Troubleshooting

**`Permission denied (publickey)` or `Could not read from remote repository` during `nix run ...#setup`** — the setup script clones over HTTPS by default, so this only happens if `CABANASHMUL_TEMPLATE_URL` is set to an SSH URL in your environment. Either unset it, or run the setup with HTTPS explicitly:

```bash
CABANASHMUL_TEMPLATE_URL=https://github.com/shmul95/cabanashmul.git nix run github:shmul95/cabanashmul#setup
```

**`home-manager: command not found`** — `nix shell home-manager#home-manager` only adds it to the current terminal. Re-run that command, or after the first successful `switch` use `home-manager` from your now-managed shell.

**`error: experimental feature 'flakes' is disabled`** — your Nix install doesn't have flakes on. Add `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf` and reopen your terminal.

**`Existing file '...' would be clobbered by switching to ...`** — you already had a dotfile Home Manager wants to manage. Re-run the switch with `-b backup` once; old files get a `.backup` suffix.

**Nothing seems to have changed in my shell** — open a *new* terminal. Your current session's environment was set before the switch ran. If you also want zsh as your login shell, see [Non-NixOS Shell Setup](#non-nixos-shell-setup).

**`profile 'personal' not found`** — `profiles/personal.nix` is missing or empty. Re-run the setup app, or copy `profiles/_example.nix.txt` to `profiles/personal.nix` and edit it.

### Quick Start (for Nix veterans)

```bash
nix run github:shmul95/cabanashmul#setup
cd cabanashmul
$EDITOR profiles/personal.nix                          # set name + email
nix shell home-manager#home-manager
home-manager switch --impure --flake . -b backup
```

## Obsidian Vault Bootstrap

If you want the public vault scaffold that pairs with GSD, generate it locally first:

```bash
nix run github:shmul95/cabanashmul#init-vault
# or, after installing the helper:
init-vault ~/vault
```

The command defaults to `~/vault` and refuses to overwrite an existing vault.

Then point `get-shmul-done` at that path from `local.nix`:

```nix
{
  programs.gsd.vault.path = "/home/you/vault";
}
```

The generated vault includes a seed note that documents the `02_Projects/<ProjectName>/GSD/` + `.planning` convention used for project planning.

## Fast Profile Switching

If you keep more than one profile (say `personal` and `work`), running `home-manager switch --impure --flake .` re-evaluates the flake every time. The bundled `build-profiles` and `switch-profile` helpers avoid that round-trip by prebuilding every profile once and then activating the cached result instantly.

```bash
build-profiles                 # prebuild every profile under $XDG_DATA_HOME/cabanashmul/
switch-profile personal        # activate the prebuilt personal profile
switch-profile work            # activate the prebuilt work profile
```

`build-profiles` discovers the profiles from `flake.lib.profileNamesStr` and builds `homeConfigurations.<user>-<profile>.activationPackage` for each. `switch-profile <name>` then runs the saved activation script directly — no Nix evaluation, no rebuild.

Re-run `build-profiles` after editing any module so the cached results stay in sync. See [`scripts/README.md`](./scripts/README.md) for details.

## AI runtimes via get-shmul-done

`get-shmul-done` ships as a default public module. It is loaded automatically on every machine unless you delete [`public/get-shmul-done.nix`](./public/get-shmul-done.nix) in your fork.

If you want to customize the module, do it in your own Home Manager layer after the public modules load. `local.nix` is the easiest place to keep machine-local tweaks:

```nix
{ ... }: {
  programs.gsd.vault.path = "/home/you/vault";
}
```

If you do not want the module at all, remove `public/get-shmul-done.nix` from your fork.

## How To Customize It

Most changes happen in [`public/`](./public/README.md).

- Want to change shell behavior? Edit [`public/zshmul.nix`](./public/zshmul.nix).
- Want to change tmux behavior? Edit [`public/tshmux.nix`](./public/tshmux.nix).
- Want to change the installed packages? Edit [`public/packages.nix`](./public/packages.nix).
- Do not want `shmulvim`? Delete [`public/shmulvim.nix`](./public/shmulvim.nix) in your fork.
- Want to add another public module? Add a new `*.nix` file in `public/`.

If the change belongs in the template, keep it in `public/`.

If the change is only for your private fork, put it in `private/`.

If a private module depends on a private repository, add that repository as a `git+ssh` flake input in [`flake.nix`](./flake.nix), then import it from `private/`. Official flake input docs:

- https://nix.dev/concepts/flakes.html
- https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html

For local machine defaults, copy [`local.example.nix`](./local.example.nix) to `local.nix` if `setup` did not already create it:

```nix
{ ... }: {
  flake.cabanashmul.context = "server";
}
```

## Directory Guide

- [`public/`](./public/README.md): public modules, load order, and the defaults this template ships with
- [`private/`](./private/README.md): private-only modules and `git+ssh` input pattern
- [`profiles/`](./profiles/README.md): default `personal` profile, extra profiles, and how profile selection works
- [`scripts/`](./scripts/README.md): setup, prebuild, and fast profile-switching helpers
- [`secrets/`](./secrets/README.md): optional agenix recipient map and how it connects to profiles

## What Is Optional

- Staying with only `profiles/personal.nix` is fine. Extra profiles are optional.
- `private/` is optional. Use it only for private modules or private inputs.
- `secrets/` is optional. Plain values and normal `~/.ssh/...` paths are still valid.

## Non-NixOS Shell Setup

Home Manager can install `zsh`, but it does not change your system login shell by itself.

After `home-manager switch`, run:

```bash
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
chsh -s "$ZSH_PATH"
```

Then log out and log back in.

---

<div align="center">

Built with Nix · Crafted by <a href="https://github.com/shmul95">@shmul95</a>

Part of the <a href="https://github.com/shmul95/zshmul">zshmul</a> · <a href="https://github.com/shmul95/tshmux">tshmux</a> · <a href="https://github.com/shmul95/shmulvim">shmulvim</a> · <strong>cabanashmul</strong> family

</div>
