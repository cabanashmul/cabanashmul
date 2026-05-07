# Testing Patterns

**Analysis Date:** 2026-05-07

## Honest Summary: No Formal Test Suite

This repository has **no automated test suite, no test framework, no test runner, and no CI workflows**. There are:

- **No** `*.test.*`, `*.spec.*`, `tests/`, or `__tests__/` files anywhere in the repo.
- **No** `nixosTest`, `runCommand`-based eval tests, or custom `flake.checks` outputs in `flake.nix` or any module.
- **No** GitHub Actions workflows. The `.github/workflows/` directory exists but is empty (`ls .github/workflows/` returns no files).
- **No** pre-commit hooks, no `.pre-commit-config.yaml`, no `lefthook.yml`, no `husky` config.
- **No** linter config files for Nix (`.statix.toml`, `deadnix` config) or shell (`.shellcheckrc`).

What exists instead is a **manual verification flow** built around `nix` evaluation, `nix build`, and a documented "Get Started" walkthrough that doubles as user-acceptance criteria. This document describes that flow honestly — it is the only way correctness is currently checked.

If you change anything in `public/`, `_builder.nix`, the script files, or `flake.nix` itself, the verification steps below are what catches breakage. Treat them as the de facto test suite until something more formal lands.

## Verification Toolchain

**Primary tools (all from the Nix ecosystem):**

| Tool | Where used | What it catches |
|------|------------|-----------------|
| `nix flake check` | manual, ad-hoc | flake schema errors, evaluation failures across declared systems, missing inputs |
| `nix flake show` | manual, ad-hoc | confirms each `homeConfigurations.<name>` and `apps.setup` is exposed |
| `nix build .#"$USER"` | manual smoke test | full Home Manager activation-package builds for the active profile |
| `nix build .#"$USER"-<profile>` | manual smoke test | per-profile build (smoke-tests `_builder.nix` profile resolution) |
| `nix run .#setup` | bootstrap test | exercises `scripts/setup.sh` end-to-end |
| `home-manager switch --impure --flake .` | full UAT | builds and activates; the only step that proves activation actually works |
| `build-profiles` (`scripts/build-profiles.sh`) | regression smoke | builds *every* discovered profile and reports failures |

**No assertion library, no mocking framework, no coverage tool.** Nix's evaluator is the only checker — if a module is malformed, evaluation fails; if a derivation is broken, `nix build` fails.

## Run Commands

```bash
# Schema + evaluation check (run from repo root).
nix flake check

# Show every output the flake exposes; useful after touching _builder.nix.
nix flake show

# Smoke-build the default profile (resolves via _builder.nix's selection chain).
nix build --impure .#"$USER"

# Smoke-build a specific profile.
nix build --impure .#"$USER"-personal
nix build --impure .#"$USER"-work

# Build every profile at once (also installed as a binary by public/packages.nix).
bash scripts/build-profiles.sh

# Exercise the bootstrap flow against the local checkout.
nix run .#setup -- /tmp/cabanashmul-test

# Full UAT: build and activate.
home-manager switch --impure --flake .
```

The `--impure` flag is required because `_builder.nix` reads `$USER` and `$HOME` via `builtins.getEnv` (`public/_builder.nix:2-4`).

## Test File Organization

**There are none.** The closest things to "test artifacts" are:

- `local.example.nix` (`local.example.nix`) — copy-to-`local.nix` template that doubles as a known-good config sample.
- `private-inputs.example.nix` (`private-inputs.example.nix`) — documentation-only example of private flake inputs; intentionally not imported.
- `profiles/_example.nix.txt` (`profiles/_example.nix.txt`) — `.txt` suffix and `_` prefix prevent auto-import; serves as the canonical reference profile shape.

These are reference fixtures, not tests. They exist to make the manual verification flow reproducible.

## What Each Manual Step Verifies

### `nix flake check`

Catches:
- Syntax errors in any auto-imported `*.nix` under `public/`, `private/`, `profiles/`.
- Missing flake inputs (e.g., a private `git+ssh://` input that is unreachable).
- Type errors against the option schema declared in `public/_options.nix` (e.g., setting `flake.cabanashmul.context = "laptop"` when the enum at `public/_options.nix:6` is `[ "desktop" "server" "wsl" ]`).
- Cross-system evaluation issues for both systems declared at `flake.nix:25` (`x86_64-linux`, `aarch64-linux`).

Does **not** catch:
- Logic errors inside an `activeProfile` consumer (`public/core.nix`) when the profile is missing the expected key — those surface only at activation time.
- Runtime shell-script errors in `scripts/*.sh`.

### `nix build .#"$USER"` (default-profile smoke test)

Catches:
- Incorrect profile-resolution logic in `public/_builder.nix:8-18` (the `if/else if` chain that picks the active profile). If selection breaks, the `${username}` alias either fails to evaluate or builds the wrong profile.
- Failures inside any `homeModule` (everything under `flake.cabanashmul.homeModules.*`) because `_builder.nix:23` collects them all via `lib.attrValues cab.homeModules` and Home Manager evaluates them together.
- Missing or broken external module imports — e.g., a bad `inputs.zshmul.homeManagerModules.default` reference in `public/zshmul.nix:3`.

### `nix build .#"$USER"-<profile>` (per-profile smoke test)

Catches:
- Profile-specific evaluation errors that only surface when that profile is active (different `git.settings`, different `ssh.matchBlocks`).
- Mismatches between profile content and what `public/core.nix:3-12` expects (`activeProfile.git.settings`, `activeProfile.ssh.matchBlocks`).

### `bash scripts/build-profiles.sh` (full regression sweep)

Reads `flake.lib.profileNamesStr` (defined at `public/_builder.nix:51-52`), builds `homeConfigurations.<user>-<profile>.activationPackage` for each profile, and aggregates failures into the `FAILED` array (`scripts/build-profiles.sh:21,33,39-42`). The non-zero exit when any profile fails makes this the closest thing to a "run all tests" command in the repo.

### `nix run .#setup`

Exercises `scripts/setup.sh` against a fresh directory. This is the only way `clone_repo`, `ensure_template_remote`, `ensure_profile_file`, `ensure_local_file`, `maybe_create_private_origin`, and `print_next_steps` (`scripts/setup.sh:16-101`) get integration-tested. There is no scripted regression for them.

### Manual UAT via README "Get Started"

The five-step walkthrough at `README.md:50-167` is the documented user-acceptance test for the project as a whole. The post-install verification list at `README.md:117-125` is explicit:

- Open a new terminal; verify a Typewritten-style single-line zsh prompt appears.
- `git config user.email` matches `profiles/personal.nix`.
- `tmux` and `nvim` launch and are configured.

If any of those fail, the bug is reproducible from a fresh checkout via the documented flow. There is no scripted equivalent.

The "Quick Start (for Nix veterans)" block at `README.md:159-167` is the condensed form of the same UAT.

## Mocking

**No mocking is used or possible** in this repo's current verification flow. Nix evaluation is hermetic; shell scripts are exercised against the real filesystem and real `git`/`gh` binaries.

When `scripts/setup.sh` is exercised, it is against a real (throwaway) target directory. To "mock" external services like the GitHub API call inside `maybe_create_private_origin` (`scripts/setup.sh:64-82`), the user simply answers `n` at the prompt — the script's interactive design **is** the test escape hatch.

## Fixtures and Factories

**No formal fixtures.** The example files listed under "Test File Organization" above are the only reusable samples. They are committed and used both as documentation and as starting points for manual verification.

## Coverage

**Not tracked.** There is no coverage tool, no target threshold, no badge.

If you want a rough mental model: the manual flow above covers the happy path of `_builder.nix`, every `homeModules.*` module, and the bootstrap script. It does **not** cover error branches in `_builder.nix` (the three `throw` cases at `public/_builder.nix:11,14,18`), the failure paths in `scripts/setup.sh`, or any cross-context behavior beyond whatever the operator's own machine happens to be.

## Test Types

**Unit tests:** none.

**Integration tests:** none formal. `nix build .#"$USER"-<profile>` is the closest analog — it integrates `_options.nix`, `_builder.nix`, every `homeModules.*` module, the active profile, and the underlying Home Manager + flake-parts evaluation.

**End-to-end tests:** none scripted. The manual UAT in `README.md:50-167` is the only end-to-end check.

## Common Patterns

Because there are no tests, the patterns below describe how to **manually verify** common change types. Adopt these in PR descriptions and commit messages until a real test layer exists.

**After editing `public/_builder.nix` or `public/_options.nix`:**

```bash
nix flake check
nix flake show                           # confirm the right outputs are exposed
nix build --impure .#"$USER"             # default-profile path
bash scripts/build-profiles.sh           # every profile path
```

**After editing any other `public/*.nix` module:**

```bash
nix flake check
nix build --impure .#"$USER"
home-manager switch --impure --flake .   # only step that proves activation
```

**After editing `scripts/*.sh`:**

```bash
shellcheck scripts/<edited>.sh           # not committed but recommended
nix build --impure .#setup               # confirms wrapShellApplication still succeeds
nix run .#setup -- /tmp/cab-$(date +%s)  # exercise setup against a fresh dir
```

`shellcheck` is not part of any committed config, but `pkgs.writeShellApplication` (used at `public/packages.nix:4-13` and `public/setup.nix:4-8`) runs `shellcheck` at build time on the embedded script content — so a `nix build` of the wrapping derivation **is** an implicit shellcheck pass for the script. This is the only static analysis the repo benefits from today.

**After editing `flake.nix` inputs:**

```bash
nix flake update                         # only when intentionally bumping
nix flake check
nix flake show
```

**Async testing:** N/A.

**Error-path testing:** must be done manually. Examples:
- To exercise `public/_builder.nix:11`, run `CABANASHMUL_PROFILE=does-not-exist nix build --impure .#"$USER"` and confirm the `throw` fires with the expected message.
- To exercise `public/_builder.nix:14`, set `flake.cabanashmul.defaultProfile = "missing"` in `local.nix` and rebuild.

## Recommended Next Steps (gap list)

These are intentionally documented here because the repo's testing story is genuinely thin:

- Add a `.github/workflows/check.yml` that runs `nix flake check` on push (the empty `.github/workflows/` directory at `/.github/workflows/` is the obvious place).
- Add a `flake.checks.<system>.builds-default-profile` derivation that calls `nix build .#"$USER"` against a fixture username so CI can run without `--impure`.
- Add a `flake.checks.<system>.scripts-pass-shellcheck` that runs `shellcheck` on `scripts/*.sh` directly (the `writeShellApplication` wrappers do this implicitly today, but a top-level check makes failures more legible).
- Capture the README "Get Started" flow as a script under `scripts/` so it can be exercised in CI inside a sandbox.

None of the above exists today. Until they do, this document is the source of truth for what "tested" means in this repo.

---

*Testing analysis: 2026-05-07*
