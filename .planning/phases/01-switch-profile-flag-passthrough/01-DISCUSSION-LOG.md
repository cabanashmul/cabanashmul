# Phase 1: switch-profile flag passthrough - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 1-switch-profile flag passthrough
**Areas discussed:** Argument parsing strategy, Flag validation scope, Usage message update

---

## Argument Parsing Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Profile-last | Profile name is always the last positional arg; all preceding args forwarded to activate | ✓ |
| Profile-first | Profile name is the first arg; all following args forwarded | |
| Separator-based | Use `--` to separate flags from profile name | |

**User's choice:** [auto] Profile-last (recommended default)
**Notes:** Success criteria examples (`switch-profile -b backup work`, `switch-profile -n work`) all place the profile name last. This matches conventional CLI patterns. Profile-first would contradict the documented interface. Separator-based adds unnecessary friction for the common case.

---

## Flag Validation Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Blind passthrough | Forward all args except last to activate without validation | ✓ |
| Validate known flags | Parse and validate `-b`, `-n`, `--show-trace`; reject unknown | |
| Hybrid | Recognize known flags for help text but forward everything | |

**User's choice:** [auto] Blind passthrough (recommended default)
**Notes:** ROADMAP explicitly says "forwards arbitrary home-manager-style activation flags". Validating would create a maintenance burden tracking Home Manager's activate flag surface. Blind passthrough is simpler, forward-compatible, and matches the "arbitrary" requirement language.

---

## Usage Message Update

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | Update to `Usage: switch-profile [FLAGS...] <profile-name>` | ✓ |
| Verbose | Add flag descriptions and examples to usage output | |

**User's choice:** [auto] Minimal (recommended default)
**Notes:** Existing scripts in the codebase use minimal usage lines. No script implements `--help`. Consistency with `build-profiles.sh` and `setup.sh` favors brevity. README and docs (Phase 4) cover detailed usage.

---

## Claude's Discretion

- Exact bash mechanics for last-arg extraction (array slicing, parameter expansion, etc.)
- Whether to preserve `exec` for the activate call (recommended: yes, no cleanup needed)

## Deferred Ideas

None — discussion stayed within phase scope.
