# Coding Conventions

**Analysis Date:** 2026-05-07

## Naming Patterns

**Nix files (lowercase, kebab-friendly):**
- One module per file, named after the program/concern it configures: `core.nix`, `direnv.nix`, `kitty.nix`, `packages.nix`, `setup.nix`, `shmulvim.nix`, `tshmux.nix`, `zshmul.nix` (all under `public/`).
- Example/template files use the suffix `.example.nix` or `.example.nix.txt` so they cannot be auto-imported as real modules: `local.example.nix`, `private-inputs.example.nix`, `profiles/_example.nix.txt`.

**Underscore-prefixed special files:**
- `public/_options.nix` and `public/_builder.nix` are prefixed with `_` because `import-tree` excludes underscore-prefixed files from auto-import. They are listed explicitly in `flake.nix` so they load before everything else.
- `profiles/_example.nix.txt` follows the same convention plus the `.txt` extension as a second safeguard.
- The comment block at `flake.nix:27-29` documents this pattern explicitly.

**Profile naming:**
- Profiles are attribute keys under `flake.cabanashmul.profiles`, named after identities/contexts: `personal`, `work`.
- One profile = one file: `profiles/personal.nix`, `profiles/work.nix`. The filename does not have to match the attribute name, but the convention in the example (`profiles/_example.nix.txt`) and README guidance (`profiles/README.md:14-19`) is `profiles/<profile-name>.nix`.
- The flake exposes outputs as `${USER}-${profileName}` (e.g. `shmul95-personal`, `shmul95-work`) plus a bare `${USER}` alias that resolves to the active profile. See `public/_builder.nix:39-45`.

**Module attribute names:**
- Each `public/*.nix` registers itself under `flake.cabanashmul.homeModules.<name>` where `<name>` matches the file's basename. Examples in `public/core.nix:2`, `public/direnv.nix:2`, `public/kitty.nix:2`, `public/packages.nix:2`, `public/zshmul.nix:2`.

**Shell scripts:**
- Lowercase kebab-case verbs: `setup.sh`, `build-profiles.sh`, `switch-profile.sh` under `scripts/`.
- Installed command names drop the `.sh` and gain a project prefix where helpful: `cabanashmul-setup` (see `public/setup.nix:5`), `build-profiles`, `switch-profile` (see `public/packages.nix:5,10`).

**Environment variables:**
- Project-specific env vars are SCREAMING_SNAKE_CASE with the `CABANASHMUL_` prefix: `CABANASHMUL_PROFILE` (deprecated, see `public/_builder.nix:4`), `CABANASHMUL_DIR` (`scripts/build-profiles.sh:4`), `CABANASHMUL_TEMPLATE_URL` (`scripts/setup.sh:4`).

## Code Style

**Indentation:**
- 2 spaces, no tabs. Verified across `flake.nix`, all `public/*.nix`, and shell scripts.

**Line endings / trailing whitespace:**
- Unix LF line endings throughout. No trailing whitespace observed.

**Formatting tool:**
- No `nixfmt` / `alejandra` / `nixpkgs-fmt` config file is committed. Style is hand-maintained.
- No `.editorconfig` is committed.

**Attribute alignment (signature style of this repo):**
- Attribute values inside related blocks are visually aligned on `=` for readability. Examples:
  - `flake.nix:5-7` aligns `nixpkgs.url`, `flake-parts.url`, `import-tree.url`.
  - `flake.nix:9-10` aligns `home-manager.url` and `home-manager.inputs.nixpkgs.follows`.
  - `public/_builder.nix:25-27` aligns `home.username`, `home.homeDirectory`, `home.stateVersion`.
  - `public/zshmul.nix:6-8`, `public/zshmul.nix:21-24`, `public/tshmux.nix:6-12` all use the same `name<space>= value;` alignment.
- Follow this when adding new fields to an existing block. For a new isolated block, plain `key = value;` without padding is also acceptable (see `public/direnv.nix`, `public/kitty.nix`).

**Semicolons and braces:**
- Every Nix attribute terminates with `;`.
- Top-level module shape is `{ ...args }: { ...body };` on the same line as the opening brace where the body is small (`public/direnv.nix:1`, `public/kitty.nix:2`).

## Module Structure Conventions

**Standard `public/` module shape:**

```nix
{ inputs, ... }: {
  flake.cabanashmul.homeModules.<name> = { pkgs, lib, activeProfile, context, ... }: {
    # Home Manager options here
  };
}
```

- The outer function takes flake-parts args (`inputs`, `lib`, `config`, ...).
- The inner Home Manager module is registered under `flake.cabanashmul.homeModules.<name>` so `_builder.nix` can collect it via `lib.attrValues cab.homeModules` (see `public/_builder.nix:23`).
- The inner module receives `pkgs`, `lib`, plus the project-specific `extraSpecialArgs` defined at `public/_builder.nix:32-36`: `inputs`, `username`, `homeDirectory`, `activeProfile`, `context`.
- Reference modules: `public/core.nix`, `public/zshmul.nix`, `public/tshmux.nix`, `public/shmulvim.nix`, `public/direnv.nix`, `public/kitty.nix`, `public/packages.nix`.

**Special non-`homeModules` modules:**
- `public/setup.nix` registers a `perSystem` flake-parts block to expose `apps.setup` and `packages.setup`. It does **not** add a `homeModules.*` entry because it builds a derivation, not a Home Manager module.
- `public/_options.nix` only declares the `flake.cabanashmul` option schema using `lib.mkOption`.
- `public/_builder.nix` consumes that option and produces `flake.homeConfigurations.*` plus `flake.lib.*` outputs.

**Context-gated modules:**
- Modules that should only activate on certain machines wrap their body in `lib.mkIf (context == "...")`. Examples: `public/kitty.nix:3` gates on `context == "desktop"`; `public/packages.nix:14` adds desktop-only packages with `lib.optionals (context == "desktop")`.

**Profile-driven configuration:**
- Modules that need identity data read from `activeProfile`, never from a hard-coded path. Use the `or` default to remain valid when the profile omits a key:
  - `public/core.nix:5`: `settings = activeProfile.git.settings or {};`
  - `public/core.nix:8`: `programs.ssh = lib.mkIf (activeProfile ? ssh) { ... };`
- Profile files write into `flake.cabanashmul.profiles.<name>` (see `profiles/_example.nix.txt` and `profiles/README.md:22-35`).

**Auto-import contract:**
- Every `*.nix` file under `public/`, `private/`, and `profiles/` is auto-imported by `import-tree` at `flake.nix:30-32`. New modules require zero registration — adding the file is the registration.
- `flake.nix:33` also conditionally imports `local.nix` when present.
- The empty `profiles.nix` at the repo root is a leftover stub that is intentionally gitignored at `/.gitignore:7`; production code lives under `profiles/`.

## Import Organization

**Nix file headers:**
- The first line is the module argset: `{ inputs, ... }:` or `{ ... }:` or `{ inputs, lib, config, ... }:`. Keep this line minimal — only request args you actually use.
- Modules that wrap an external Home Manager module always import it first inside the inner module body via `imports = [ inputs.<flake>.homeManagerModules.default ];` (see `public/zshmul.nix:3`, `public/tshmux.nix:3`, `public/shmulvim.nix:3`).

**No path aliases:**
- Plain relative paths everywhere (`./public/_options.nix`, `../scripts/build-profiles.sh`).

## Error Handling

**Nix evaluation errors:**
- `_builder.nix` uses `throw` to fail fast with an actionable message that lists known profiles. See `public/_builder.nix:11`, `public/_builder.nix:14`, `public/_builder.nix:18`.
- Always include the offending value and the list of valid alternatives in throw strings, formatted as `"cabanashmul: <what went wrong> (have: <comma-separated list>)"`.

**Shell script errors:**
- All scripts start with `#!/usr/bin/env bash` and `set -euo pipefail` (`scripts/setup.sh:1-2`, `scripts/build-profiles.sh:1-2`, `scripts/switch-profile.sh:1-2`).
- Required commands are validated with a small `need_cmd` helper that prints `"<script>: required command not found: <cmd>"` to stderr and exits 1 (`scripts/setup.sh:9-14`).
- User-facing error messages follow the pattern `"<script-name>: <message>" >&2` (`scripts/setup.sh:18`, `scripts/build-profiles.sh:15`, `scripts/switch-profile.sh:6,14`).
- Failures are accumulated into a `FAILED` array and reported at the end rather than aborting on first failure when running multiple builds (`scripts/build-profiles.sh:21,33,39-42`).
- Exit codes: `1` for any error condition; scripts never use other exit codes.

## Logging

**No structured logging framework.**
- Shell scripts use bare `echo` for progress (`scripts/build-profiles.sh:8,19,27`) and `echo ... >&2` for errors.
- Multi-line user guidance uses heredoc: `cat <<'EOF' ... EOF` (`scripts/setup.sh:85-100`).
- Decorative arrows for status indicate progression: `==>` for major steps, `->` for results (`scripts/build-profiles.sh:27,31`).

## Comments

**When to comment:**
- Comment non-obvious mechanics, especially anything that depends on `import-tree`'s filter or flake-parts behavior. Example: `flake.nix:27-29` explains why `_options.nix` and `_builder.nix` must be listed explicitly.
- Inline comments inside example files describe what the user must replace (`secrets/secrets.nix:1-2,4`, `local.example.nix:1-2,5,7`).
- The `.example.nix.txt` files lead with a multi-line comment block describing how to copy and adapt them (`profiles/_example.nix.txt:1-3`).

**Style:**
- Single-line comments use `#`. Nix has no multi-line comment syntax in this codebase — multi-line guidance is a stack of `#` lines (see `private-inputs.example.nix`).

## Function Design

**Nix:**
- `_builder.nix` defines `mkConfig` as a 2-arg function (`name: profile:`) that returns the result of `homeManagerConfiguration`. Local helpers are defined in a `let ... in` block at the top of the file (`public/_builder.nix:1-37`).
- Prefer a small `let` block over deeply nested attribute lookups; the active profile resolution chain is a stepped `if / else if` ladder rather than a nested ternary.

**Shell:**
- Functions are short, single-purpose, named with snake_case verbs: `need_cmd`, `clone_repo`, `ensure_template_remote`, `ensure_profile_file`, `ensure_local_file`, `maybe_create_private_origin`, `print_next_steps` (`scripts/setup.sh`).
- The script bottom is a flat list of function calls in execution order (`scripts/setup.sh:103-110`) — no `main()` wrapper.

## Module Design

**Exports:**
- Nix modules export options and config under `flake.cabanashmul.*`. They never `inherit`-export through `let ... in`.
- Shell scripts are imported into Nix via `builtins.readFile ../scripts/<script>.sh` and wrapped with `pkgs.writeShellApplication` so `runtimeInputs` is explicit (`public/packages.nix:4-13`, `public/setup.nix:4-8`). Always declare `runtimeInputs` — never rely on the user's `PATH`.

**Barrel files:**
- None. The dendritic / `import-tree` pattern replaces barrel files.

## Secrets Discipline (agenix)

- `secrets/` is opt-in. The repo ships only `secrets/secrets.nix` (the recipient map) and `secrets/README.md`. Encrypted `*.age` files are not committed in the public template.
- `secrets/secrets.nix` declares which SSH public keys decrypt each secret (`secrets/secrets.nix:6-11`). It is not encrypted itself — it only contains public keys.
- The placeholder `me = "ssh-ed25519 AAAA_REPLACE_ME"` at `secrets/secrets.nix:5` is a load-bearing sentinel: leaving it unedited means no key can decrypt anything.
- Edit secrets with `nix run github:ryantm/agenix -- -e <file>.age` (documented at `secrets/secrets.nix:2`).
- Profiles reference decrypted paths via `config.age.secrets.<name>.path` instead of plain strings (pattern shown in `profiles/_example.nix.txt:9-10,14-15`). Never write a plain email or key path when an agenix path is available.
- `agenix` is wired in as a flake input at `flake.nix:12-13` with `inputs.nixpkgs.follows = "nixpkgs"` to keep the dependency graph aligned.
- **Never** commit: `local.nix`, `profiles/*.nix` (other than READMEs), `private/*` (except `private/README.md`), `private-inputs.nix`, `result*` symlinks. All of these are listed in `/.gitignore`.
- The `.example.*` and `_example.*` files are the only profile/local/private templates that may be committed.

## README Conventions (per directory)

Every functional subdirectory has its own `README.md`. The repo follows a consistent structure across them:

- **Top-level `README.md`** (`README.md`): hero block with badges, one-line tagline, anchor nav, `Highlights`, `Architecture` (with directory tree), `Get Started` (numbered steps), `Fast Profile Switching`, `How To Customize It`, `Directory Guide` (links to each subdir README), `What Is Optional`, `Troubleshooting`, footer block.
- **Sub-directory READMEs** follow this shape:
  1. `# <dirname>` (lowercase, matches directory).
  2. One-paragraph purpose statement.
  3. Section explaining how files in this directory are loaded or used (`## How It Loads`, `## Setup Workflow`, `## How Profile Selection Works`).
  4. List of every file in the directory with a backtick link and a one-line purpose. See `public/README.md:24-33`, `scripts/README.md:7-9`.
  5. "How to add" / "How to remove" / "Typical workflow" prescriptive sections.
  6. Inline code fences (` ```nix ` / ` ```bash `) for any pattern the reader is expected to copy.

- **Cross-references** always use relative markdown links with backticks around the path: `` [`public/zshmul.nix`](./public/zshmul.nix) ``. Never bare URLs to the same repo.
- **Step numbering** is consistent: `1.`, `2.`, ... never `1)`. Bullet lists use `-`, never `*`.
- **Code fence languages** are always declared (`bash`, `nix`).

When adding a new top-level directory, mirror this structure or the directory will feel out of place against the existing READMEs.

---

*Convention analysis: 2026-05-07*
