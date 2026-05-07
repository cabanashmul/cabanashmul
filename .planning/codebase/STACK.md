# Technology Stack

**Analysis Date:** 2026-05-07

## Languages

**Primary:**
- Nix (flake-based, uses the `nixos-unstable` Nixpkgs channel) — every module under `public/`, `private/`, `profiles/`, plus `flake.nix`, `local.example.nix`, `private-inputs.example.nix`, `secrets/secrets.nix`.
- Bash (POSIX, `set -euo pipefail`) — `scripts/setup.sh`, `scripts/build-profiles.sh`, `scripts/switch-profile.sh`. Wrapped into Nix-built executables via `pkgs.writeShellApplication` in `public/setup.nix` and `public/packages.nix`.

**Secondary:**
- Markdown — top-level `README.md`, `CHANGELOG.md`, and per-directory `README.md` files in `public/`, `private/`, `profiles/`, `scripts/`, `secrets/`.

## Runtime

**Environment:**
- Nix with flakes enabled (`experimental-features = nix-command flakes`). Required by `README.md` Get Started section.
- Home Manager (standalone, non-NixOS). Invoked as `home-manager switch --impure --flake .` per `README.md`.
- Linux only. `flake.nix` declares `systems = [ "x86_64-linux" "aarch64-linux" ]`. The builder in `public/_builder.nix` hardcodes `pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux`, so aarch64 evaluation goes through the x86_64 package set as currently wired.
- Shell helpers depend on POSIX `coreutils`, `nix`, `git`, `openssh`, `gh` — declared as `runtimeInputs` in `public/setup.nix` and `public/packages.nix`.

**Package Manager:**
- Nix (the project itself is a Nix flake; there is no Node/Python/Cargo manifest).
- Lockfile: `flake.lock` (present, version 7).

## Frameworks

**Core:**
- `flake-parts` (`github:hercules-ci/flake-parts`) — top-level orchestration via `inputs.flake-parts.lib.mkFlake` in `flake.nix`. Lets each `*.nix` module under `public/` contribute options/config that get merged.
- `home-manager` (`github:nix-community/home-manager`) — user-level dotfile/package manager. Configurations are produced by `inputs.home-manager.lib.homeManagerConfiguration` in `public/_builder.nix`.
- `import-tree` (`github:vic/import-tree`) — dendritic auto-import. `flake.nix` calls `(inputs.import-tree ./public).imports` (and the same for `./private`, `./profiles`) so any `*.nix` file dropped into those folders is loaded automatically. Files prefixed with `_` (such as `public/_options.nix`, `public/_builder.nix`) are excluded by import-tree's default filter and are listed explicitly first in `flake.nix` so they load before the rest.

**Testing:**
- Not detected. There is no `tests/`, no flake `checks` output, no CI test runner.

**Build/Dev:**
- `nix build` / `nix run` — the canonical build interface. `public/setup.nix` exposes `apps.setup` (via `flake-parts` `perSystem`) so `nix run github:shmul95/cabanashmul#setup` works.
- `pkgs.writeShellApplication` — used to package each shell script as a derivation with explicit `runtimeInputs`. See `public/setup.nix` (cabanashmul-setup) and `public/packages.nix` (build-profiles, switch-profile).
- `home-manager switch --impure --flake .` — the everyday rebuild command. `--impure` is required because `public/_builder.nix` reads `$USER`, `$HOME`, and `$CABANASHMUL_PROFILE` via `builtins.getEnv`.

## Key Dependencies

**Critical (declared in `flake.nix` `inputs`):**
- `nixpkgs` — `github:NixOS/nixpkgs/nixos-unstable`. Single source of `pkgs` for every module. Locked rev: `0726a0ecb6d4e08f6adced58726b95db924cef57` (`flake.lock`).
- `flake-parts` — `github:hercules-ci/flake-parts`. Provides `mkFlake` and the per-system module structure.
- `import-tree` — `github:vic/import-tree`. Drives the dendritic loading model that is the project's main value proposition.
- `home-manager` — `github:nix-community/home-manager` with `inputs.nixpkgs.follows = "nixpkgs"`. Used in standalone (non-NixOS) mode.
- `agenix` — `github:ryantm/agenix` with `inputs.nixpkgs.follows = "nixpkgs"`. Optional encrypted-secret support; consumed by profiles via `config.age.secrets.<name>.path` (see `profiles/_example.nix.txt`). The starter does not enable an `age` module by default — `secrets/secrets.nix` is the recipient map and the user is expected to opt in.

**Custom inputs (sibling family repos by `@shmul95`):**
- `zshmul` — `github:shmul95/zshmul` with `inputs.nixpkgs.follows = "nixpkgs"`. Imported as `inputs.zshmul.homeManagerModules.default` in `public/zshmul.nix`. Provides `programs.zshmul.*` (Typewritten-style prompt, oh-my-zsh plugins, `extraPackages`, etc.).
- `tshmux` — `github:shmul95/tshmux` with `inputs.nixpkgs.follows = "nixpkgs"`. Imported as `inputs.tshmux.homeManagerModules.default` in `public/tshmux.nix`. Provides `programs.tshmux.*` (tmux configuration, theme, status line).
- `shmulvim` — `github:shmul95/shmulvim` with `inputs.nixpkgs.follows = "nixpkgs"`. Imported as `inputs.shmulvim.homeManagerModules.default` in `public/shmulvim.nix`. Provides `programs.shmulvim.*` (Neovim configuration).

**Transitive (in `flake.lock` only, not directly referenced):**
- `flake-compat` (lix-project) — pulled in by `nvf` under `shmulvim`.
- `flake-utils` (numtide) — pulled in by `zshmul` and `shmulvim`.
- `nvf`, `mnw`, `ndg` — Neovim framework deps under `shmulvim`.
- `wrappers` (lassulus), `typewritten-theme` (reobin) — under `zshmul`.
- `tmuxPlugin*` (tpm, sensible, yank, continuum, vim-tmux-navigator) — non-flake fixed sources under `tshmux` and (transitively) `zshmul`'s `tshmux`.
- `darwin` (lnl7) — pulled in by `agenix` but unused on Linux.

**Infrastructure:**
- `pkgs.writeShellApplication` — used to package every shell script as a Nix derivation (`public/setup.nix`, `public/packages.nix`).
- `lib.mkOption` / `lib.types.submodule` — `public/_options.nix` defines the `flake.cabanashmul` option schema (`context`, `defaultProfile`, `profiles`, `homeModules`).
- `lib.mapAttrs'` / `lib.nameValuePair` — `public/_builder.nix` builds one `homeConfigurations.<user>-<profile>` entry per profile plus a default `<user>` alias.

## Configuration

**Environment variables read at evaluation time (in `public/_builder.nix`):**
- `USER` — username for `home.username` and the `homeConfigurations` attribute names. Falls back to `"your-username"`.
- `HOME` — `home.homeDirectory`. Falls back to `/home/${username}`.
- `CABANASHMUL_PROFILE` — explicit profile selector. Deprecated per `README.md` and `CHANGELOG.md` 1.0.0, but still honored. Throws if it names a profile that does not exist.

**Environment variables read by scripts:**
- `CABANASHMUL_TEMPLATE_URL` — overrides the clone URL in `scripts/setup.sh` (defaults to `https://github.com/shmul95/cabanashmul.git`).
- `CABANASHMUL_DIR` — flake directory used by `scripts/build-profiles.sh` (defaults to `$PWD`).
- `XDG_DATA_HOME` — base directory for prebuilt profile symlinks in `scripts/build-profiles.sh` and `scripts/switch-profile.sh` (falls back to `$HOME/.local/share`); both write/read `$XDG_DATA_HOME/cabanashmul/result-<profile>`.

**Configuration files:**
- `flake.nix` — flake inputs and the four-layer import order (`_options` → `_builder` → `public/*` → `private/*` → `profiles/*` → `local.nix`).
- `flake.lock` — pinned versions of every input.
- `local.nix` (gitignored, copied from `local.example.nix` by `scripts/setup.sh`) — sets `flake.cabanashmul.context` (`"desktop" | "server" | "wsl"`) and optionally `flake.cabanashmul.defaultProfile`.
- `profiles/<name>.nix` (gitignored except `profiles/README.md` and `profiles/_example.nix.txt`) — declares `flake.cabanashmul.profiles.<name>` with `git.settings.user` and `ssh.matchBlocks`.
- `secrets/secrets.nix` — agenix recipient map (`<file>.age` → list of `publicKeys`). Optional.
- `private-inputs.example.nix` — documentation only; explains how to add `git+ssh` private inputs directly to `flake.nix` because flake `inputs` must be a static attrset.
- `.gitignore` — keeps `result*`, `local.nix`, `private/*` (except `private/README.md`), `profiles/*.nix`, `private-inputs.nix`, and the legacy `profiles.nix` out of the repo.

**Build:**
- `flake-parts` `perSystem` block in `public/setup.nix` produces `packages.setup` and `apps.setup` for `x86_64-linux` / `aarch64-linux`.
- The active profile is selected by `public/_builder.nix` in this order: `CABANASHMUL_PROFILE` → `flake.cabanashmul.defaultProfile` → `personal` → the only profile, if exactly one → throw.

## Platform Requirements

**Development:**
- Linux (`x86_64-linux` is the actually supported target; `aarch64-linux` is listed in `flake.nix` `systems` but the builder hardcodes the x86_64 package set).
- Nix with flakes enabled.
- Git in `PATH` (used by `scripts/setup.sh`).
- Optional: `gh` CLI (only when answering "yes" to the private-repo prompt in `scripts/setup.sh`).
- Optional: SSH agent + key on GitHub (only if `CABANASHMUL_TEMPLATE_URL` is overridden to an SSH URL, or for `git+ssh://` private inputs added under `private/`).

**Production:**
- The "deployment target" for this repo is the user's own machine — `home-manager switch` writes activation scripts and updates the user profile. There is no remote deploy. Three supported machine contexts (selected via `flake.cabanashmul.context`):
  - `desktop` — enables `kitty` (`public/kitty.nix`) and adds `discord`, `firefox`, `kitty` to `home.packages` (`public/packages.nix`).
  - `server` — default; minimal package set.
  - `wsl` — same as `server` for now (the option exists in `public/_options.nix` but no module branches on it).
- `home.stateVersion = "25.05"` is set as a default in `public/_builder.nix`.

---

*Stack analysis: 2026-05-07*
