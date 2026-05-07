# Phase 01, Plan 01 — Summary

**One-line:** Added flag parsing to `switch-profile.sh` that translates `-b`, `-n`/`--dry-run`, and `--show-trace` into Home Manager environment variables before calling `activate --driver-version 1`.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add flag parsing and env-var translation | `c22499a` |
| 1b | Fix edge case: flag used as sole argument | `41b29da` |
| 2 | Verify error scenarios 5-7 (automated) | — |
| 2 | Verify activation scenarios 1-4 (manual) | pending user approval |

## Deviations

- **Post-loop flag guard added:** The original implementation (commit `c22499a`) didn't catch the case where a flag like `-b` is the only argument — the `while (( $# > 1 ))` loop never enters, so `-b` gets treated as the profile name. Commit `41b29da` adds a post-loop check that detects when the profile name starts with `-` and prints a specific error.

## Files Modified

- `scripts/switch-profile.sh` — rewritten with flag parsing, env-var exports, `--driver-version 1`, and flag-as-profile-name guard

## Known Issues

- None
