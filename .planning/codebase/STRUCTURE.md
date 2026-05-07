# Codebase Structure

**Analysis Date:** 2026-05-07

## Directory Layout

```
cabanashmul/
├── flake.nix                       # Flake entry: inputs + flake-parts mkFlake imports
├── flake.lock                      # Pinned input revisions
├── README.md                       # User-facing docs (pitch, get-started, troubleshooting)
├── CHANGELOG.md                    # Release history (1.0.0, 0.3.0, 0.2.0, 0.1.0)
├── local.example.nix               # Template for the gitignored `local.nix`
├── local.nix                       # (gitignored) machine-local context + defaultProfile
├── private-inputs.example.nix      # Documentation-only example for private SSH-gated inputs
├── profiles.nix                    # Tracked but empty placeholder; gitignored at runtime
├── result -> /nix/store/...        # Build artifact symlink (not source)
├── .gitignore                      # Excludes /result, /local.nix, /private/*, /profiles/*.nix, ...
├── .github/
│   └── workflows/                  # (currently empty) reserved for CI
├── .claude/
│   └── settings.local.json         # Claude Code local settings (not committed by default)
├── .planning/
│   └── codebase/                   # GSD codebase maps (this directory)
├── public/                         # Tracked Home Manager modules (auto-imported)
│   ├── README.md                   # Public load order + module catalog
│   ├── _options.nix                # `flake.cabanashmul` option schema (loaded explicitly)
│   ├── _builder.nix                # Builds homeConfigurations + flake.lib (loaded explicitly)
│   ├── core.nix                    # programs.git + programs.ssh from active profile
│   ├── direnv.nix                  # programs.direnv with nix-direnv
│   ├── kitty.nix                   # programs.kitty (only when context = "desktop")
│   ├── packages.nix                # build-profiles, switch-profile, optional desktop pkgs
│   ├── setup.nix                   # `apps.setup` / `packages.setup` wrapping scripts/setup.sh
│   ├── shmulvim.nix                # programs.shmulvim
│   ├── tshmux.nix                  # programs.tshmux
│   └── zshmul.nix                  # programs.zshmul
├── private/                        # (entire dir gitignored except README.md) optional
│   └── README.md                   # How to add private modules + git+ssh inputs
├── profiles/                       # Per-identity modules (`*.nix` gitignored)
│   ├── README.md                   # Default profile + selection rules
│   └── _example.nix.txt            # Template for `personal.nix`, `work.nix`, ...
├── secrets/                        # Optional agenix recipient metadata
│   ├── README.md                   # When to use agenix + workflow
│   └── secrets.nix                 # SSH publicKeys -> secret name map
└── scripts/                        # Shell helpers consumed by Nix wrappers
    ├── README.md                   # Setup + fast-switch workflow
    ├── setup.sh                    # Bootstrap (cloned, exposed via apps.setup)
    ├── build-profiles.sh           # Prebuild every profile under XDG_DATA_HOME
    └── switch-profile.sh           # exec the saved activation script
```

## Directory Purposes

**`public/`:**
- Purpose: The tracked, forkable Home Manager base. Every other layer overlays on top of this.
- Contains: Option schema, builder, identity wiring, tool integrations (`zshmul`, `tshmux`, `shmulvim`, `kitty`, `direnv`), the package set, and the setup app.
- Key files: `public/_options.nix`, `public/_builder.nix`, `public/core.nix`, `public/packages.nix`, `public/setup.nix`.
- Loading: `flake.nix:29` imports `_options.nix` and `_builder.nix` explicitly, then `flake.nix:30` calls `(inputs.import-tree ./public).imports` to auto-pick the rest.

**`private/`:**
- Purpose: Optional gitignored overlay for modules that should not appear in the public template.
- Contains: User-defined `flake.cabanashmul.homeModules.<name>` files plus README.md.
- Key files: only `private/README.md` is tracked; everything else is excluded by `.gitignore` (`/private/*` with `!/private/README.md`).
- Loading: `flake.nix:31` imports the tree only when `./private` exists.

**`profiles/`:**
- Purpose: Per-identity Git/SSH bundles selected by `CABANASHMUL_PROFILE` / `defaultProfile`.
- Contains: `_example.nix.txt` template, `README.md`, and gitignored `<name>.nix` files such as `profiles/personal.nix`, `profiles/work.nix`.
- Key files: `profiles/_example.nix.txt`, `profiles/README.md`.
- Loading: `flake.nix:32` imports the tree only when `./profiles` exists; `_example.nix.txt` is excluded both by extension (not `.nix`) and by the underscore-prefix filter.

**`secrets/`:**
- Purpose: Optional agenix recipient map. Not part of Home Manager evaluation.
- Contains: `secrets.nix` (SSH public keys → encrypted file mapping) and `README.md`.
- Loading: Not auto-imported by the flake. Consumed by agenix tooling outside `home-manager switch`.

**`scripts/`:**
- Purpose: Shell-script source for the bootstrap and fast-switch helpers.
- Contains: `setup.sh`, `build-profiles.sh`, `switch-profile.sh`, `README.md`.
- Loading: Read at evaluation time by `public/setup.nix` and `public/packages.nix` via `builtins.readFile`. They are not executed by the flake; `pkgs.writeShellApplication` rewraps them.

**`.github/workflows/`:**
- Purpose: Reserved for GitHub Actions CI. Currently empty.

**`.planning/codebase/`:**
- Purpose: GSD codebase maps (ARCHITECTURE.md, STRUCTURE.md, etc.) consumed by `/gsd-plan-phase` and `/gsd-execute-phase`.
- Generated: Yes (by GSD agents).
- Committed: Yes.

**`.claude/`:**
- Purpose: Claude Code local settings (`settings.local.json`). Treat as machine-local.

## Key File Locations

**Entry Points:**
- `flake.nix` — Flake declaration; the only top-level Nix file Nix actually evaluates as the entry.
- `public/_options.nix` — Option schema; loaded first inside `mkFlake`.
- `public/_builder.nix` — Outputs synthesizer; loaded second.
- `public/setup.nix` — Declares `apps.setup` for `nix run .#setup`.

**Configuration:**
- `local.example.nix` — Template for the gitignored `local.nix` (`flake.cabanashmul.context`, optional `defaultProfile`).
- `local.nix` — Active machine-local config (gitignored).
- `profiles/_example.nix.txt` — Template for new profile files.
- `profiles/<name>.nix` — Active profile (gitignored).
- `secrets/secrets.nix` — agenix recipients (only when secrets are used).
- `private-inputs.example.nix` — Documentation for adding private SSH inputs to `flake.nix` (not imported).

**Core Logic:**
- `public/_builder.nix` — Profile resolution, `mkConfig`, `flake.homeConfigurations`, `flake.lib.*`.
- `public/core.nix` — Active profile → `programs.git` / `programs.ssh`.
- `public/packages.nix` — `home.packages` plus `build-profiles` / `switch-profile` shell wrappers.

**Module Surface:**
- `public/zshmul.nix` — zsh stack via the `zshmul` flake input.
- `public/tshmux.nix` — tmux stack via the `tshmux` flake input.
- `public/shmulvim.nix` — neovim stack via the `shmulvim` flake input.
- `public/kitty.nix` — kitty terminal (desktop only).
- `public/direnv.nix` — direnv + nix-direnv.

**Helper Scripts:**
- `scripts/setup.sh` — used by `public/setup.nix`.
- `scripts/build-profiles.sh` — installed as the `build-profiles` command.
- `scripts/switch-profile.sh` — installed as the `switch-profile` command.

**Documentation:**
- `README.md` — top-level user guide.
- `CHANGELOG.md` — release notes.
- `public/README.md`, `private/README.md`, `profiles/README.md`, `secrets/README.md`, `scripts/README.md` — per-directory guides.

## Naming Conventions

**Files:**
- `*.nix` for every Nix module. Lowercase, hyphenated (`build-profiles.sh`) or single-word (`zshmul.nix`).
- Underscore prefix `_<name>.nix` marks files that `import-tree`'s default filter must skip. Used for files that the flake imports explicitly in a controlled order or that are not modules at all.
  - `public/_options.nix` — must be merged into the option schema before any module declares values.
  - `public/_builder.nix` — must run after the schema but is imported explicitly so the load order is unambiguous.
  - `profiles/_example.nix.txt` — example template; `.txt` suffix also keeps it out of the `*.nix` import set even if a future filter changes.
- `*.example.nix` (or `.example.nix.txt`) marks copy-me-then-edit templates: `local.example.nix`, `private-inputs.example.nix`, `profiles/_example.nix.txt`.
- `*.sh` for shell scripts. Always paired with a Nix wrapper that embeds them via `builtins.readFile` rather than executed directly.
- Per-directory `README.md` follows a "what lives here / how to add / how to remove" structure (see `public/README.md`).

**Directories:**
- Single-word, lowercase (`public`, `private`, `profiles`, `secrets`, `scripts`).
- Each top-level directory carries one concern; cross-cutting Nix lives only in `public/`.

**Module identifiers:**
- Each module registers itself under `flake.cabanashmul.homeModules.<name>` where `<name>` matches the file stem (e.g. `core.nix` → `homeModules.core`, `tshmux.nix` → `homeModules.tshmux`). Maintain this mapping for new modules so removals are obvious.
- Profiles use `flake.cabanashmul.profiles.<name>`; keep `<name>` matching the file stem (`profiles/personal.nix` → `profiles.personal`).

**Import-tree filter contract:**
- `import-tree` skips any path whose basename starts with `_` and any non-`.nix` file. `flake.nix` relies on this to avoid double-importing `_options.nix` / `_builder.nix` and to keep `_example.nix.txt` out of the graph.
- Adding a new file with an underscore prefix means committing to also adding it to the explicit `imports` list in `flake.nix:29`.

## Where to Add New Code

**A new public Home Manager module:**
- Create `public/<feature>.nix` with the canonical shape:
  ```nix
  { ... }: {
    flake.cabanashmul.homeModules.<feature> = { ... }: {
      # Home Manager config here
    };
  }
  ```
- No edit to `flake.nix` needed; `import-tree` picks it up.
- Use `public/direnv.nix` as the minimal reference, `public/zshmul.nix` for an input-backed module.

**A new private module:**
- Create `private/<feature>.nix` (entire dir is gitignored except README).
- If it consumes a private flake input, add the input directly to `flake.nix:4-21` per `private-inputs.example.nix`.

**A new profile:**
- Copy `profiles/_example.nix.txt` to `profiles/<name>.nix`.
- The file is gitignored automatically; commit only via `git add -f` if the private fork should track it.

**A new helper script:**
- Add `scripts/<name>.sh`.
- Wrap it in `public/packages.nix` (for an installed command) or in a new `public/<name>.nix` (for a flake `apps.<name>` entry, mirroring `public/setup.nix`).
- Always read the script via `builtins.readFile ../scripts/<name>.sh` and wrap with `pkgs.writeShellApplication` so `runtimeInputs` are explicit.

**Machine-local override:**
- Edit `local.nix` (create from `local.example.nix` if missing). Set `flake.cabanashmul.context` and optionally `flake.cabanashmul.defaultProfile`.

**A new flake input:**
- Add it to the `inputs` attrset in `flake.nix:4-21`. Always pin transitively: `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"`. Use `git+ssh://` URLs only in private forks.

**A new GSD planning artifact:**
- Add under `.planning/`. Codebase maps go in `.planning/codebase/`. Phase plans live elsewhere under `.planning/` per the GSD workflow.

## Special Directories

**`/result` (symlink):**
- Purpose: Latest `nix build` output for whichever Home Manager configuration was last activated.
- Generated: Yes (by Nix).
- Committed: No (`/result` in `.gitignore`).

**`result-*` (per-profile prebuilds):**
- Purpose: Symlinks to per-profile activation packages, written by `scripts/build-profiles.sh:30` under `${XDG_DATA_HOME:-$HOME/.local/share}/cabanashmul/`.
- Generated: Yes (`build-profiles`).
- Committed: No (`.gitignore` excludes `result-*` at the repo root for safety).

**`profiles.nix` (root, empty):**
- Purpose: Historical placeholder. Tracked in git but empty; gitignored at runtime via `/profiles.nix` to prevent accidental population. Not imported.
- Generated: No.
- Committed: Yes (zero bytes).

**`private-inputs.nix` (gitignored):**
- Purpose: If a future workflow regenerates private inputs, the `.gitignore` already excludes it. Today it does not exist; treat the example file as documentation only.

**`flake.lock`:**
- Purpose: Pins every input. Always commit changes from `nix flake update` together with the corresponding code change.

---

*Structure analysis: 2026-05-07*
