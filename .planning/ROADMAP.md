---
project: cabanashmul
milestone: v1.1
milestone_name: GSD
last_updated: 2026-05-07
phase_count: 4
---

# Roadmap — Milestone v1.1 GSD

| # | Phase | Goal | Requirements | Success criteria |
|---|-------|------|--------------|------------------|
| 1 | switch-profile flag passthrough | `switch-profile` forwards Home Manager activation flags to `activate` | ERGO-01, ERGO-02, ERGO-03 | 4 |
| 2 | update-cabanashmul helper | Single command for `template` merge + rebuild + optional switch | ERGO-04, ERGO-05, ERGO-06 | 4 |
| 3 | Optional get-shmul-done module | Opt-in `cabanashmul.gsd.enable` wiring `inputs.get-shmul-done` | GSD-01, GSD-02, GSD-03, GSD-04 | 5 |
| 4 | v1.1 docs & release | README, CHANGELOG, tag `1.1.0` | DOCS-01, DOCS-02, DOCS-03 | 3 |

**Coverage:** 4 phases · 13 requirements · 100% mapped.

---

## Phase 1: switch-profile flag passthrough

**Goal:** `switch-profile <profile>` forwards arbitrary `home-manager`-style activation flags (`-b`, `-n`, `--show-trace`) to the underlying `$RESULT_LINK/activate` script. Currently flags are not parsed or passed through.

**Requirements:** ERGO-01, ERGO-02, ERGO-03

**Canonical refs:**
- `scripts/switch-profile.sh` — current activation logic
- `scripts/build-profiles.sh` — sibling script (parallel build)
- `.planning/codebase/CONVENTIONS.md` — shell discipline (`set -euo pipefail`, `need_cmd` pattern)

**Success criteria:**
1. `switch-profile -b backup work` activates the `work` profile and forwards `-b backup` to `activate`; pre-existing dotfiles get renamed to `<file>.backup` instead of erroring.
2. `switch-profile -n work` runs the activation in dry-run mode and exits without modifying state.
3. `switch-profile --show-trace work` produces a Nix evaluator stack trace when activation fails.
4. `switch-profile work` (no flags) preserves current behavior — fails fast if `result-work` doesn't exist.

**Not in scope:** `-B` build-then-switch (deferred — see SWITCH-BUILD-01).

---

## Phase 2: update-cabanashmul helper

**Goal:** A `scripts/update-cabanashmul.sh` helper that fetches the `template` remote, merges `template/main`, and rebuilds profiles. Ships in the template so every cabanashmul user gets it after `nix run ...#setup`.

**Requirements:** ERGO-04, ERGO-05, ERGO-06

**Canonical refs:**
- `scripts/setup.nix` (or equivalent) — establishes the `template` remote that this helper depends on
- `scripts/build-profiles.sh` — invoked for the rebuild step
- `scripts/switch-profile.sh` — invoked for `--switch` flag
- `.planning/codebase/CONVENTIONS.md` — shell discipline (`set -euo pipefail`, `need_cmd`)
- `.planning/codebase/INTEGRATIONS.md` — current `template` remote contract

**Success criteria:**
1. `update-cabanashmul` (no args) runs `git fetch template && git merge template/main && build-profiles` and exits 0 on a clean merge.
2. `update-cabanashmul --no-build` performs only the fetch + merge.
3. `update-cabanashmul --switch <profile>` runs the full cycle and activates `<profile>` at the end.
4. If the `template` remote does not exist, the script prints a clear error pointing the user at `nix run github:shmul95/cabanashmul#setup` and exits non-zero.

**Not in scope:** Conflict-resolution UX. A failing `git merge` should leave the user in the standard merge state (the script just exits non-zero).

---

## Phase 3: Optional get-shmul-done module

**Goal:** Add `public/gsd.nix` exposing `cabanashmul.gsd.enable` (default `false`). When enabled, the flake wires `inputs.get-shmul-done` and imports its Home Manager module. Users who leave it disabled (the default) build identically to today — no extra fetch, no extra eval cost.

**Requirements:** GSD-01, GSD-02, GSD-03, GSD-04

**External prerequisite:** `get-shmul-done` must be public on GitHub with a `1.0.0` tag before this phase merges. See PROJECT.md "External prerequisite".

**Canonical refs:**
- `flake.nix` — `inputs` block, `imports` wiring
- `public/_options.nix` — option schema (where `cabanashmul.gsd.enable` is declared)
- `public/_builder.nix` — output assembly (decides whether to import `get-shmul-done`'s HM module)
- `.planning/codebase/ARCHITECTURE.md` — flake-parts + import-tree conventions
- `.planning/codebase/STACK.md` — current `inputs` set

**Success criteria:**
1. `nix flake show .` lists `cabanashmul.gsd.enable` as a documented option with `default = false` and a description.
2. With `cabanashmul.gsd.enable = false` (default), `nix build .#"$USER"` does not fetch `get-shmul-done` and produces a result identical to v1.0.x in shape (same modules imported).
3. With `cabanashmul.gsd.enable = true` and a profile that opts in, `home-manager switch --impure --flake .` activates the GSD module and the user gets `.claude/`, `.codex/`, etc., as managed by `get-shmul-done`.
4. Toggling `cabanashmul.gsd.enable` between true and false rebuilds cleanly without manual intervention.
5. `inputs.get-shmul-done.url` pins to a tagged release (`github:shmul95/get-shmul-done?ref=1.0.0`), not `main`.

**Not in scope:** Vault scaffolding, `init-vault` app — they live in `get-shmul-done`.

---

## Phase 4: v1.1 docs & release

**Goal:** Document the v1.1 surface (GSD module, new flags, helper script), bump CHANGELOG, tag `1.1.0`.

**Requirements:** DOCS-01, DOCS-02, DOCS-03

**Canonical refs:**
- `README.md` — top-level documentation
- `CHANGELOG.md` — release log (existing format; v1.0 entry as template)
- `scripts/README.md` — directory-level docs that reference `switch-profile` / `update-cabanashmul`

**Success criteria:**
1. README has an "Optional: AI runtimes via get-shmul-done" section with a 3–5 line copy-pastable enable example. Section is linked from the top-of-README nav row.
2. `CHANGELOG.md` has a `1.1.0 - 2026-MM-DD` entry covering all v1.1 requirements (ERGO-*, GSD-*) in the existing prose-bullet style.
3. Git tag `1.1.0` exists on the release commit and is pushed to `origin`.

**Not in scope:** Marketing announcements, blog posts, social.
