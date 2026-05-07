<!-- refreshed: 2026-05-07 -->
# Architecture

**Analysis Date:** 2026-05-07

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                      flake.nix (entry)                       │
│  Declares inputs (nixpkgs, flake-parts, import-tree,         │
│  home-manager, agenix, zshmul, tshmux, shmulvim) and         │
│  composes flake-parts modules via mkFlake.                   │
└────────┬────────────────────────────────────────────────────┘
         │ imports (in this order)
         ▼
┌─────────────────────────────────────────────────────────────┐
│  Option schema + builder (loaded explicitly first)           │
│   `public/_options.nix`   → defines flake.cabanashmul        │
│   `public/_builder.nix`   → produces flake.homeConfigurations│
└────────┬────────────────────────────────────────────────────┘
         │ then import-tree auto-discovers `*.nix`
         ▼
┌──────────────────┬──────────────────┬───────────────────────┐
│  public/*.nix    │  private/*.nix   │   profiles/*.nix      │
│  base modules    │  (optional,      │   per-identity git    │
│  declare         │   gitignored)    │   + ssh settings      │
│  homeModules.*   │  homeModules.*   │   profiles.<name> = … │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         └──────────────────┴─────────────────────┘
                            │ merges into
                            ▼
┌─────────────────────────────────────────────────────────────┐
│           config.flake.cabanashmul (merged option set)       │
│   { context, defaultProfile, profiles, homeModules }         │
└────────┬────────────────────────────────────────────────────┘
         │ consumed by `_builder.nix` mkConfig
         ▼
┌─────────────────────────────────────────────────────────────┐
│   flake.homeConfigurations.<USER>                            │
│   flake.homeConfigurations.<USER>-<profile>                  │
│   flake.lib.mkHomeConfig                                     │
│   flake.lib.profileNamesStr                                  │
│   apps.setup / packages.setup (from `public/setup.nix`)      │
└─────────────────────────────────────────────────────────────┘
         │ activated by
         ▼
┌─────────────────────────────────────────────────────────────┐
│   home-manager switch --impure --flake .                     │
│   (or prebuilt activation script via `switch-profile`)       │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Flake entry | Declare inputs and orchestrate flake-parts + import-tree | `flake.nix` |
| Option schema | Define the `flake.cabanashmul` submodule (context, defaultProfile, profiles, homeModules) | `public/_options.nix` |
| Builder | Compute active profile and emit `flake.homeConfigurations` + `flake.lib.*` | `public/_builder.nix` |
| Identity wiring | Translate active profile into `programs.git` / `programs.ssh` | `public/core.nix` |
| Tool modules | Register Home Manager modules for shell/editor/terminal stack | `public/zshmul.nix`, `public/tshmux.nix`, `public/shmulvim.nix`, `public/kitty.nix`, `public/direnv.nix` |
| Package set | Install `build-profiles`, `switch-profile`, optional desktop packages | `public/packages.nix` |
| Setup app | Expose `nix run .#setup` bootstrap | `public/setup.nix` |
| Private overlay | Optional gitignored modules + SSH-gated inputs (loaded only if dir exists) | `private/*.nix` |
| Profile registry | Per-identity `git`/`ssh` settings under `flake.cabanashmul.profiles.<name>` | `profiles/*.nix` |
| Local overrides | Machine-local `context` + `defaultProfile` (gitignored) | `local.nix` (template: `local.example.nix`) |
| Secrets metadata | agenix recipient map for encrypted secrets | `secrets/secrets.nix` |
| Helper scripts | Bootstrap, prebuild, fast switch shell scripts | `scripts/setup.sh`, `scripts/build-profiles.sh`, `scripts/switch-profile.sh` |

## Pattern Overview

**Overall:** Dendritic flake — `flake-parts` composition + `import-tree` auto-discovery on top of Home Manager.

**Key Characteristics:**
- Every `*.nix` file under `public/`, `private/`, and `profiles/` is auto-imported as a flake-parts module; adding a module is creating a file.
- Underscore-prefixed files (`_options.nix`, `_builder.nix`, `_example.nix.txt`) are excluded by `import-tree`'s default filter, so the flake imports them explicitly when they must load before everything else.
- Configuration is declarative and merge-based: each module contributes to the shared `flake.cabanashmul` option set rather than mutating a central file.
- Public/private layering: the public template is forkable as-is; private modules and SSH-gated inputs live in a separate, gitignored layer.
- Profiles are first-class identity units. The flake exposes one `homeConfigurations` entry per profile plus a default `<USER>` alias.
- `--impure` evaluation is required: `_builder.nix` reads `$USER`, `$HOME`, and `$CABANASHMUL_PROFILE` from the environment at evaluation time.

## Layers

**Flake / orchestration:**
- Purpose: Declare inputs, choose systems, drive imports.
- Location: `flake.nix`
- Contains: `inputs`, `outputs = inputs: flake-parts.lib.mkFlake { ... }`.
- Depends on: `flake-parts`, `import-tree`, `home-manager`, `agenix`, `nixpkgs`, sibling project flakes (`zshmul`, `tshmux`, `shmulvim`).
- Used by: `home-manager switch`, `nix run .#setup`, `build-profiles`.

**Public base (`public/`):**
- Purpose: Tracked Home Manager modules shipped by the template.
- Location: `public/`
- Contains: Option schema (`_options.nix`), builder (`_builder.nix`), identity wiring (`core.nix`), tool integrations (`zshmul.nix`, `tshmux.nix`, `shmulvim.nix`, `kitty.nix`, `direnv.nix`), packages (`packages.nix`), setup app (`setup.nix`).
- Depends on: flake `inputs`, the merged `flake.cabanashmul` config.
- Used by: every consumer of `flake.homeConfigurations`.

**Private overlay (`private/`):**
- Purpose: Modules that should not appear in the public template (private repos, employer-specific config).
- Location: `private/` (entire directory gitignored except `private/README.md`).
- Contains: `homeModules.*` definitions that wire SSH-gated flake inputs into Home Manager.
- Depends on: private `inputs` added directly to `flake.nix` in the private fork.
- Used by: merged via the same `homeModules` attrset as `public/`.

**Profiles (`profiles/`):**
- Purpose: Per-identity Git + SSH settings.
- Location: `profiles/` (every `*.nix` is gitignored; only `_example.nix.txt` and `README.md` are tracked).
- Contains: `flake.cabanashmul.profiles.<name>` definitions consumed by `public/core.nix`.
- Depends on: the `flake.cabanashmul.profiles` option from `_options.nix`.
- Used by: `_builder.nix` (profile selection) and `core.nix` (identity wiring).

**Local overrides (`local.nix`):**
- Purpose: Machine-local context (`context`, `defaultProfile`) without leaking into git.
- Location: repo root; gitignored. Template is `local.example.nix`.
- Contains: a single attrset assigning `flake.cabanashmul.context` and optionally `defaultProfile`.
- Loaded last so it can override anything from `public/`, `private/`, or `profiles/`.

**Secrets (`secrets/`):**
- Purpose: agenix recipient metadata; pure declarative, not auto-imported into the Home Manager evaluation.
- Location: `secrets/secrets.nix`.
- Used by: agenix tooling outside the flake; consumed indirectly when profiles reference `config.age.secrets.<name>.path`.

## Data Flow

### Primary build path (`home-manager switch --impure --flake .`)

1. `flake.nix:23` `outputs` invokes `flake-parts.lib.mkFlake` with `systems = [ "x86_64-linux" "aarch64-linux" ]` (`flake.nix:25`).
2. `flake.nix:29` imports `./public/_options.nix` first, registering the `flake.cabanashmul` option submodule (`public/_options.nix:2`).
3. `flake.nix:29` imports `./public/_builder.nix` next, deferring its execution because `config.flake.cabanashmul` is read during evaluation (`public/_builder.nix:6`).
4. `flake.nix:30` calls `inputs.import-tree ./public` and concatenates its `.imports`, pulling in every non-underscore `*.nix` in `public/` (`core.nix`, `direnv.nix`, `kitty.nix`, `packages.nix`, `setup.nix`, `shmulvim.nix`, `tshmux.nix`, `zshmul.nix`).
5. `flake.nix:31` does the same for `./private` if the directory exists; `flake.nix:32` for `./profiles`; `flake.nix:33` adds `./local.nix` directly when present.
6. flake-parts merges every imported module's `flake.cabanashmul.*` contributions into one `config.flake.cabanashmul` value (homeModules from `public/`, profiles from `profiles/`, context/defaultProfile from `local.nix`).
7. `public/_builder.nix:7-18` resolves `activeName` from `CABANASHMUL_PROFILE` → `flake.cabanashmul.defaultProfile` → `personal` → the only profile, throwing if a requested profile is missing.
8. `public/_builder.nix:20-37` defines `mkConfig name profile`, calling `inputs.home-manager.lib.homeManagerConfiguration` with `pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux`, the merged `homeModules`, default `home.username` / `home.homeDirectory` / `home.stateVersion = "25.05"`, `nixpkgs.config.allowUnfree = true`, and `extraSpecialArgs = { inputs, username, homeDirectory, activeProfile = profile, context = cab.context }`.
9. `public/_builder.nix:39-45` emits `flake.homeConfigurations."${username}-${name}"` for every profile and `flake.homeConfigurations."${username}"` for the active one.
10. `home-manager switch` reads `flake.homeConfigurations.<USER>` (or `<USER>-<profile>` when explicit), realises the activation derivation, and runs `result/activate`.

### Active-profile consumption

1. `extraSpecialArgs.activeProfile` is threaded into every Home Manager module evaluation.
2. `public/core.nix:2-13` reads `activeProfile.git.settings` and `activeProfile.ssh.matchBlocks`, lifting them into `programs.git.settings` and `programs.ssh.matchBlocks` (only when the profile defines `ssh`).
3. `extraSpecialArgs.context` flows into `public/kitty.nix:3` (gates kitty on `desktop`) and `public/packages.nix:14` (adds `discord firefox kitty` only on `desktop`).

### Fast profile switching

1. `scripts/build-profiles.sh:9-12` runs `nix eval --impure --raw <FLAKE_DIR>#lib.profileNamesStr` to discover profile names from `flake.lib.profileNamesStr` (declared in `public/_builder.nix:51-52`).
2. `scripts/build-profiles.sh:23-36` loops over the names and runs `nix build .#homeConfigurations.<user>-<profile>.activationPackage`, symlinking each result under `${XDG_DATA_HOME:-$HOME/.local/share}/cabanashmul/result-<profile>`.
3. `scripts/switch-profile.sh:13-21` resolves that symlink and `exec`s the saved `activate` script — no flake re-evaluation, no rebuild.

### Setup app

1. `nix run github:shmul95/cabanashmul#setup` resolves `apps.setup` declared in `public/setup.nix:11-14`.
2. `public/setup.nix:4-8` wraps `scripts/setup.sh` with `pkgs.writeShellApplication`, embedding `git`, `coreutils`, `openssh`, `gh` as runtime inputs.
3. `scripts/setup.sh:103-110` clones the template (HTTPS by default per `CABANASHMUL_TEMPLATE_URL`), renames `origin` to `template`, copies `profiles/_example.nix.txt → profiles/personal.nix`, copies `local.example.nix → local.nix`, and optionally creates a private GitHub `origin`.

**State Management:**
- All configuration state lives in the merged `config.flake.cabanashmul` attrset — there is no runtime mutation. Activation state is captured in `/nix/store` derivations and the `result` symlink (`/home/shmul95/Repositories/cabanashmul/result` is a build artifact, not source).

## Key Abstractions

**`flake.cabanashmul` option submodule:**
- Purpose: The shared schema every layer contributes to.
- Location: `public/_options.nix`
- Pattern: flake-parts module options with `lib.types.submodule` containing `context` (`enum [ "desktop" "server" "wsl" ]`), `defaultProfile` (`nullOr str`), `profiles` (`attrsOf attrs`), `homeModules` (`attrsOf deferredModule`).

**`homeModules` attrset:**
- Purpose: Each public/private module registers itself by name; the builder feeds `lib.attrValues cab.homeModules` into `homeManagerConfiguration.modules`.
- Examples: `public/core.nix:2`, `public/zshmul.nix:2`, `public/tshmux.nix:2`, `public/shmulvim.nix:2`, `public/kitty.nix:2`, `public/direnv.nix:2`, `public/packages.nix:2`.
- Pattern: `flake.cabanashmul.homeModules.<name> = { ... }: { ... };` — values are `deferredModule`, evaluated against Home Manager's module system rather than flake-parts'.

**`profiles` attrset:**
- Purpose: Free-form per-identity bag consumed by `core.nix` and selectable by name.
- Examples: structure documented in `profiles/_example.nix.txt`; gitignored real files like `profiles/personal.nix`, `profiles/work.nix`.
- Pattern: `flake.cabanashmul.profiles.<name> = { git.settings.user = { ... }; ssh.matchBlocks.<host> = { ... }; }`.

**`extraSpecialArgs`:**
- Purpose: Inject `inputs`, `username`, `homeDirectory`, `activeProfile`, `context` into every Home Manager module without making them flake-parts modules.
- Location: `public/_builder.nix:32-36`.
- Pattern: Modules destructure these from their argument set (e.g. `{ inputs, ... }`, `{ activeProfile, ... }`, `{ context, ... }`).

**`flake.lib` helpers:**
- `flake.lib.mkHomeConfig` (`public/_builder.nix:47-49`) — programmatic factory accepting `extraModules` / `extraSpecialArgs`.
- `flake.lib.profileNamesStr` (`public/_builder.nix:51-52`) — space-separated profile names, consumed by `scripts/build-profiles.sh`.

## Entry Points

**Flake entry — `flake.nix`:**
- Triggers: `nix build`, `nix run`, `home-manager switch --flake .`, any flake consumer.
- Responsibilities: Declare `inputs`, set `systems`, compose imports (`./public/_options.nix`, `./public/_builder.nix`, `import-tree ./public`, `import-tree ./private` if present, `import-tree ./profiles` if present, `./local.nix` if present).

**Option schema — `public/_options.nix`:**
- Triggers: Loaded explicitly as the first import inside `mkFlake`.
- Responsibilities: Register the `flake.cabanashmul` submodule with `context`, `defaultProfile`, `profiles`, `homeModules` options.

**Builder — `public/_builder.nix`:**
- Triggers: Loaded explicitly second; evaluated lazily once `config.flake.cabanashmul` has been merged.
- Responsibilities: Resolve the active profile, define `mkConfig`, expose `flake.homeConfigurations.<USER>` / `<USER>-<profile>` and `flake.lib.*`.

**Setup app — `public/setup.nix`:**
- Triggers: `nix run .#setup` (or `nix run github:shmul95/cabanashmul#setup`).
- Responsibilities: Wrap `scripts/setup.sh` as a `writeShellApplication` and expose it as `apps.setup` and `packages.setup` via flake-parts' `perSystem`.

**Switching scripts:**
- `scripts/build-profiles.sh` — installed as the `build-profiles` command via `public/packages.nix:5-9`.
- `scripts/switch-profile.sh` — installed as the `switch-profile` command via `public/packages.nix:10-13`.

## Architectural Constraints

- **Impure evaluation required:** `public/_builder.nix:2-4` calls `builtins.getEnv "USER"` / `"HOME"` / `"CABANASHMUL_PROFILE"`. Builds must be invoked with `--impure`; falling back to defaults (`your-username`, `/home/your-username`) yields a non-functional configuration.
- **Static `inputs` attrset:** `private-inputs.example.nix` documents that flake `inputs` cannot be merged dynamically; private SSH-gated inputs must be added directly to `flake.nix` in the private fork. There is no runtime input injection.
- **Single-system pkgs:** `public/_builder.nix:22` hardcodes `inputs.nixpkgs.legacyPackages.x86_64-linux` even though `flake.nix:25` advertises `aarch64-linux`. Home Manager evaluation is effectively `x86_64-linux`-only today; aarch64 users get an `x86_64-linux` build.
- **Profile resolution is throwing:** A missing `CABANASHMUL_PROFILE` value or `defaultProfile` causes `_builder.nix:11`/`:14`/`:18` to `throw` rather than silently falling back. There is no graceful degradation when no profiles exist except the literal string `"none"` (`_builder.nix:17`).
- **Underscore filter is contractual:** `import-tree` excludes any path whose basename starts with `_`. Files like `_options.nix`, `_builder.nix`, and `_example.nix.txt` rely on this; renaming them without updating `flake.nix` would either cause double-import or skip them entirely.
- **`profiles.nix` (root, empty):** Tracked but empty placeholder; gitignored separately by `/profiles.nix` line in `.gitignore`. Not part of the import graph.
- **`local.nix` loaded last:** Because it is appended to `imports` after `private/` and `profiles/`, it has the final word on `flake.cabanashmul.context` and `defaultProfile`. Any module that wants to be overridable must rely on flake-parts' default merge semantics.

## Anti-Patterns

### Putting profile data in `public/`

**What happens:** A user adds `flake.cabanashmul.profiles.personal = { ... }` to a file under `public/`.
**Why it's wrong:** `public/` is tracked and forkable; identity (real name, email, SSH host blocks) leaks into git. The intent of the dendritic split is that `public/` carries no identity.
**Do this instead:** Create `profiles/<name>.nix` (gitignored by `.gitignore`) following `profiles/_example.nix.txt`.

### Adding inputs from `private-inputs.example.nix` as if it were imported

**What happens:** A user expects `private-inputs.example.nix` to be auto-merged into `flake.nix`.
**Why it's wrong:** `private-inputs.example.nix:1` explicitly states it is documentation only; Nix flake `inputs` must be a static attrset and dynamic merging is not supported.
**Do this instead:** Edit `flake.nix` directly in the private fork to add `git+ssh://...` inputs, then `nix flake update`.

### Editing `home.nix`

**What happens:** A user looks for a central `home.nix` to edit Home Manager settings.
**Why it's wrong:** There is no central file. The dendritic pattern means each concern lives in its own module under `public/` (or `private/`).
**Do this instead:** Add a new `public/<feature>.nix` (or `private/<feature>.nix`) that registers a `flake.cabanashmul.homeModules.<name>` deferred module — see `public/direnv.nix` as the minimal template.

### Reading `$CABANASHMUL_PROFILE` from new code

**What happens:** A new module reads the env var directly to decide behavior.
**Why it's wrong:** Profile selection is centralized in `public/_builder.nix:4-18`. Reading it elsewhere fragments the resolution rules and breaks `flake.lib.mkHomeConfig` and the `<USER>` alias.
**Do this instead:** Consume `activeProfile` (and `context`) from `extraSpecialArgs`, exactly like `public/core.nix:2`.

### Underscore-prefixing a module that should auto-import

**What happens:** Naming a new file `public/_my-module.nix`.
**Why it's wrong:** `import-tree`'s default filter excludes underscore-prefixed paths, so the module silently never loads.
**Do this instead:** Use a plain name like `public/my-module.nix`.

## Error Handling

**Strategy:** Fail fast at evaluation time via `throw`.

**Patterns:**
- Profile mismatches throw with a list of available profiles (`public/_builder.nix:11`, `:14`, `:18`).
- Setup script uses `set -euo pipefail` and `need_cmd` guards (`scripts/setup.sh:1`, `:9-14`); missing `git` aborts before any clone.
- `build-profiles` aggregates failures into a `FAILED` array and exits non-zero only at the end (`scripts/build-profiles.sh:21`, `:39-42`).
- `switch-profile` checks for the prebuilt symlink and prints actionable guidance otherwise (`scripts/switch-profile.sh:13-17`).

## Cross-Cutting Concerns

**Logging:** Shell scripts use plain `echo`; nix evaluation has no logging beyond `throw` messages. Home Manager activation logs come from upstream Home Manager.

**Validation:** Enforced through Nix's type system — `_options.nix` constrains `context` to a fixed enum and `homeModules` to `deferredModule`s.

**Authentication:** SSH identities live in `profiles/<name>.nix` (`ssh.matchBlocks`) or, when agenix is used, via `secrets/secrets.nix` recipient declarations and `config.age.secrets.<name>.path` references.

**Configuration override order:** `public/` defaults → `private/` overlays → `profiles/` identity → `local.nix` machine overrides → `CABANASHMUL_PROFILE` env var (selection only). flake-parts' default `lib.mkDefault`/`lib.mkOverride` semantics apply to module-level conflicts.

---

*Architecture analysis: 2026-05-07*
