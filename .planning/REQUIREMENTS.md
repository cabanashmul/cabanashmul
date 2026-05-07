---
project: cabanashmul
milestone: v1.1
milestone_name: GSD
last_updated: 2026-05-07
---

# Requirements — Milestone v1.1 GSD

## v1.1 Requirements

### ERGO — Script ergonomics

- [ ] **ERGO-01**: User can pass `-b backup` to `switch-profile <profile>` to forward Home Manager activation flag (renames pre-existing dotfiles instead of failing).
- [ ] **ERGO-02**: User can pass `-n` (or `--dry-run`) to `switch-profile <profile>` to preview activation without making changes.
- [ ] **ERGO-03**: User can pass `--show-trace` to `switch-profile <profile>` to surface evaluator stack traces on activation errors.
- [ ] **ERGO-04**: User can run `update-cabanashmul` to fetch the `template` remote, merge `template/main`, and rebuild profiles in one step.
- [ ] **ERGO-05**: `update-cabanashmul --no-build` performs the fetch + merge without rebuilding.
- [ ] **ERGO-06**: `update-cabanashmul --switch <profile>` rebuilds and activates the named profile after merging.

### GSD — get-shmul-done integration

- [ ] **GSD-01**: `cabanashmul.gsd.enable` option exists (boolean, default `false`) and is documented in `public/_options.nix`.
- [ ] **GSD-02**: When `cabanashmul.gsd.enable = true`, the flake imports `inputs.get-shmul-done`'s Home Manager module without affecting users who leave it disabled.
- [ ] **GSD-03**: `flake.nix` declares `inputs.get-shmul-done.url = "github:shmul95/get-shmul-done"` pinned to a tagged release (`?ref=1.0.0` or equivalent).
- [ ] **GSD-04**: A user with `cabanashmul.gsd.enable = false` (the default) can build and activate any profile without `get-shmul-done` being fetched or evaluated.

### DOCS — Release & documentation

- [ ] **DOCS-01**: README contains a new "Optional: AI runtimes via get-shmul-done" section that explains opt-in usage with a copy-pastable example.
- [ ] **DOCS-02**: `CHANGELOG.md` has a `1.1.0` entry describing the GSD module, ergonomic flags, and `update-cabanashmul`.
- [ ] **DOCS-03**: Repository has a git tag `1.1.0` on the release commit.

## Future Requirements (deferred)

- **DARWIN-01**: Add `aarch64-darwin` and `x86_64-darwin` to `systems` in `flake.nix` and verify build paths. (codebase map flagged this gap.)
- **CI-01**: Add a `.github/workflows/` job that runs `nix flake check` and `nix build .#"$USER"` against a sample profile on push.
- **SWITCH-BUILD-01**: `switch-profile -B <profile>` to build then activate in one step. Deferred per discussion — `build-profiles && switch-profile X` covers the case.
- **VAULT-INIT-01**: Interactive vault scaffolding when `programs.gsd.vault.path = null`. Lives in the `get-shmul-done` repo as `nix run github:shmul95/get-shmul-done#init-vault`, not in cabanashmul.

## Out of Scope

- **get-shmul-done repo internals** — audit, `vault.path = null` default, `init-vault` flake app, URL flip to `github:`, public release, and `1.0.0` tag are all in the `get-shmul-done` repo. cabanashmul only consumes the result as a flake input.
- **Interactive prompts in `switch-profile`** — non-interactive callers (scripts, CI) must continue to work. Hints printed on first run are fine; `[y/N]` blocks are not.
- **Auto-running `init-vault` on switch** — same reason: keeps `switch-profile` scriptable.

## Traceability

| REQ-ID | Phase |
|--------|-------|
| ERGO-01, ERGO-02, ERGO-03 | Phase 1 |
| ERGO-04, ERGO-05, ERGO-06 | Phase 2 |
| GSD-01, GSD-02, GSD-03, GSD-04 | Phase 3 |
| DOCS-01, DOCS-02, DOCS-03 | Phase 4 |
