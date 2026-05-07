# Codebase Concerns

**Analysis Date:** 2026-05-07

## Tech Debt

**Empty placeholder file (`profiles.nix`) — MEDIUM:**
- Issue: A 0-byte `profiles.nix` sits at the repo root. It is not imported by `flake.nix` (which only imports `./public/_options.nix`, `./public/_builder.nix`, the `public/`, `private/`, `profiles/` trees, and `./local.nix`). The file is also explicitly gitignored (`/profiles.nix`), so its presence in a tracked working tree is contradictory.
- Files: `profiles.nix` (0 bytes), `.gitignore` (line `/profiles.nix`), `flake.nix:33`
- Impact: Confuses readers ("is profiles.nix the entry point or is profiles/ ?"). Older commit `382704c replace profiles.example.nix with profiles/_example.nix.txt` suggests this is a vestigial leftover from the migration to the `profiles/` directory.
- Fix approach: Delete `profiles.nix` from the working tree. The `.gitignore` rule can stay as a safety net or be removed alongside the file.

**Deprecated `CABANASHMUL_PROFILE` env var still wired in `_builder.nix` — MEDIUM:**
- Issue: Per commit `3b8e9a4` and the 1.0.0 changelog entry, `CABANASHMUL_PROFILE` is deprecated in favor of per-user flake outputs (`.#"$USER"-<profile>`). The variable is still read and honored at the top of `public/_builder.nix` and is the first branch in the active-profile resolution chain.
- Files: `public/_builder.nix:4` (`envProfile = builtins.getEnv "CABANASHMUL_PROFILE"`), `public/_builder.nix:9-11`, `profiles/README.md:50`, `public/README.md:20`, `README.md:48`, `CHANGELOG.md:11`
- Impact: New users still see the variable in three READMEs and may keep depending on a path the maintainer wants to retire. Two ways to select a profile (env var vs. flake attr) means two failure modes to document and test.
- Fix approach: Pick a target removal version. Add a `builtins.trace`/`lib.warn` when `envProfile != ""` so users see a runtime deprecation notice. Eventually drop branches at `public/_builder.nix:9-11` and update READMEs to mention the env var only in a "compatibility" appendix.

**Hard-coded `x86_64-linux` in builder despite multi-system declaration — MEDIUM:**
- Issue: `flake.nix` declares `systems = [ "x86_64-linux" "aarch64-linux" ]`, but `mkConfig` in the builder always uses `inputs.nixpkgs.legacyPackages.x86_64-linux`.
- Files: `flake.nix:25`, `public/_builder.nix:22`
- Impact: On `aarch64-linux` hosts the Home Manager configuration is still built against `x86_64-linux` packages, which either fails or silently produces an x86_64 closure for an aarch64 user. The declared `aarch64-linux` support is effectively cosmetic.
- Fix approach: Detect the host system at build time (e.g. via `pkgs.stdenv.hostPlatform.system` from a `perSystem` block, or `builtins.currentSystem` under `--impure`) and pass the correct `legacyPackages.<system>` into `homeManagerConfiguration`.

**Setup script's "rename `origin` to `template`" is destructive — MEDIUM:**
- Issue: `scripts/setup.sh:32-36` runs `git remote rename origin template` whenever `origin` exists and `template` does not. The setup app is meant to be a one-shot bootstrap, but if a user re-runs it (or runs it inside an unrelated repo via `nix run github:shmul95/cabanashmul#setup .` style invocation) the existing `origin` of that repo gets renamed.
- Files: `scripts/setup.sh:27-41`
- Impact: A misuse can silently mutate someone else's repository's remotes. The script does not verify that the current directory is actually a freshly cloned cabanashmul checkout before renaming.
- Fix approach: Guard the rename with a sentinel check (e.g., presence of `flake.nix` containing `cabanashmul`) or require the working directory to match what `clone_repo` just produced (the script already does `cd "$TARGET_DIR"` so that invariant holds for the happy path; document this and refuse to run if invoked outside it).

**Nix store symlink (`result`) committed to working tree — LOW:**
- Issue: A symlink `result -> /nix/store/hy9xj8miyr7m3xqk8a8m68br6xy0y0cx-home-manager-generation` lives in the repo root. It is gitignored (`/result`, `result-*` in `.gitignore`), so it will not be committed, but it clutters `ls` and gets stale every time the user rebuilds.
- Files: `result` (symlink), `.gitignore`
- Impact: Cosmetic; new contributors may wonder whether the symlink is part of the project. `build-profiles` uses `$XDG_DATA_HOME/cabanashmul/result-<profile>` instead, so this `result` link is left behind by ad-hoc `nix build` invocations.
- Fix approach: Document in the README that `result` is a transient `nix build` output and can be removed. Optionally, add a `clean` script or note in `scripts/README.md`.

**Six tracked README/example files modified but uncommitted — LOW:**
- Issue: `git status` shows six modified-but-unstaged files in the working tree. Diffs reveal substantive doc improvements (clearer "default profile is `personal`" wording in `profiles/README.md`, throwing on missing-profile in `public/_builder.nix`, optional-by-default framing in `secrets/README.md` and `local.example.nix`, "How to remove something" section in `public/README.md`, flake-input doc links in `private/README.md`). These changes look ready to ship and improve the post-1.0.0 onboarding story, but have not been committed.
- Files: `local.example.nix`, `private/README.md`, `profiles/README.md`, `public/README.md`, `public/_builder.nix`, `secrets/README.md`
- Impact: Risk of losing the work to a stash/reset accident; users cloning `main` see a less helpful 1.0.0 doc set than what is on disk locally.
- Fix approach: Commit each file as an atomic change (per personal commit policy). The `public/_builder.nix` change is a behavior change (better error message + new `personal` fallback) and warrants its own commit separate from the docs.

## Known Bugs

**`activeName = "none"` reaches `mkConfig` when no profiles exist — MEDIUM:**
- Symptoms: When `profiles/` is empty (or no `profiles.<name>` attr is ever defined), `activeName` is set to the literal string `"none"`. The fallback `let ap = if cab.profiles ? ${activeName} then cab.profiles.${activeName} else {}; in { "${username}" = mkConfig activeName ap; }` then builds a Home Manager configuration named `"${username}"` whose `activeProfile` is `{}`.
- Files: `public/_builder.nix:17` (`else if profileNames == [] then "none"`), `public/_builder.nix:43-45`
- Trigger: Bootstrap before running `setup` (or after deleting `profiles/personal.nix`). Run `nix build .#"$USER"`.
- Workaround: Always create `profiles/personal.nix` before evaluating. The setup script does this, but the README's troubleshooting block (`profile 'personal' not found`) hints this state is reachable.
- Fix approach: Throw a helpful error from `_builder.nix` when `profileNames == []` instead of returning the sentinel `"none"`, or skip emitting `homeConfigurations.${username}` entirely when there are no profiles.

**`maybe_create_private_origin` reads stdin under `nix run` — LOW:**
- Symptoms: `scripts/setup.sh:70-71` does `printf "Create a private GitHub repo and set it as origin? [y/N] "; read -r reply`. Under `nix run github:shmul95/cabanashmul#setup` the script's stdin is the terminal in normal use, but in non-interactive contexts (CI, piped invocations) `read` will fail or block silently.
- Files: `scripts/setup.sh:64-82`
- Trigger: `nix run github:shmul95/cabanashmul#setup </dev/null` or running the bootstrap from an automation pipeline.
- Workaround: Run interactively only.
- Fix approach: Detect `[ -t 0 ]` and skip the prompt (treat as "n") when stdin is not a TTY; or expose a `CABANASHMUL_CREATE_PRIVATE_ORIGIN={yes,no,ask}` env var.

## Security Considerations

**`--impure` is the default and documented bootstrap flag — MEDIUM:**
- Risk: The whole flake reads `$USER`, `$HOME`, and `$CABANASHMUL_PROFILE` via `builtins.getEnv`. This is required for the dynamic per-user output strategy, but it means flake evaluations cannot be reproduced from a hash alone — two users on the same commit will get different `homeConfigurations`.
- Files: `public/_builder.nix:2-4`, `README.md:108-113`, `scripts/build-profiles.sh:10`
- Current mitigation: `--impure` is documented as required, not as a code smell. The `flake.cabanashmul.profiles` attrset still pins identity per profile.
- Recommendations: Continue documenting `--impure` openly. Consider exposing a pure variant like `flake.lib.mkHomeConfig { username = "..."; }` for users who want CI-pinned builds.

**`secrets/secrets.nix` ships with a placeholder public key — MEDIUM:**
- Risk: The committed file contains `me = "ssh-ed25519 AAAA_REPLACE_ME";` and four `.age` recipients (`github_personal.age`, `github_work.age`, `git-email-personal.age`, `git-email-work.age`) all gated on that placeholder.
- Files: `secrets/secrets.nix:5`
- Current mitigation: agenix will refuse to encrypt against a malformed key, so accidental encryption with the placeholder fails fast. The README warns "Replace with the output of: cat ~/.ssh/id_ed25519.pub".
- Recommendations: Add a `setup.sh` step (or a separate `secrets-setup` helper) that substitutes the user's real public key on first use. At minimum, add a `throw` when the `AAAA_REPLACE_ME` literal is detected at evaluation time.

**`.age` files are not explicitly gitignored — LOW:**
- Risk: `.gitignore` covers `/private/*`, `/profiles/*.nix`, `/local.nix`, `/private-inputs.nix`, and the `result` symlinks, but does not explicitly cover `*.age`. agenix files are encrypted and *meant* to be committed, so this is correct by design — but unencrypted intermediates (e.g. `*.age.txt` while editing) could leak.
- Files: `.gitignore`
- Current mitigation: agenix's edit workflow uses temp files outside the repo; the user has to deliberately copy plaintext in.
- Recommendations: Add a comment in `secrets/README.md` reminding users not to commit decrypted intermediates, and optionally add `*.age.plain`, `*.age.txt`, `*.age.dec` patterns to `.gitignore`.

**`profiles/*.nix` may contain plaintext identity data — LOW:**
- Risk: The starter explicitly supports plain values in `profiles/*.nix` (per `secrets/README.md:7`). `profiles/*.nix` is gitignored by `/profiles/*.nix`, so this is safe by default — but `setup.sh:92` actively tells users to `git add -f profiles/personal.nix local.nix` when committing personalizations.
- Files: `scripts/setup.sh:91-93`, `.gitignore`
- Current mitigation: Documentation positions the user's personalized fork as private, and the setup app offers to create a private GitHub repo as `origin`.
- Recommendations: Make the README "publish your fork as private" guidance more prominent. Consider warning in `setup.sh` when `git add -f profiles/personal.nix` is executed against a remote that resolves to a public GitHub repo.

## Performance Bottlenecks

**Every `home-manager switch` re-evaluates the full flake — LOW:**
- Problem: With multiple profiles, switching contexts re-evaluates every public/private/profile module.
- Files: `public/_builder.nix:39-45`, `scripts/build-profiles.sh`, `scripts/switch-profile.sh`
- Cause: Home Manager's normal flow.
- Improvement path: Already addressed by the `build-profiles` / `switch-profile` helpers — prebuilt activation packages live under `$XDG_DATA_HOME/cabanashmul/result-<profile>`. Document this more prominently for multi-profile users (the README already does, but the troubleshooting block could cross-link it).

## Fragile Areas

**`import-tree` filename filter relies on underscore prefix — MEDIUM:**
- Files: `flake.nix:27-30`, `public/_options.nix`, `public/_builder.nix`
- Why fragile: `_options.nix` and `_builder.nix` are excluded from auto-import by `import-tree`'s default underscore-prefix filter, then explicitly listed before the directory walk so they load first. Anyone renaming or splitting these files can break the load order without an obvious failure mode (modules that consume `flake.cabanashmul.<x>` may evaluate before the option type is declared).
- Safe modification: Keep the underscore prefix on any file that needs to load before the rest of `public/`. Document this convention in `public/README.md` (currently it documents the whole-directory import but not the underscore opt-out).
- Test coverage: None. There is no flake check or evaluation test verifying load order.

**`profiles/_example.nix.txt` is a `.txt` to dodge auto-import — LOW:**
- Files: `profiles/_example.nix.txt`
- Why fragile: The example uses `.txt` instead of `.nix` because `import-tree` would otherwise pull it in. The leading underscore would also exclude it, so the `.txt` extension is belt-and-suspenders. New contributors may rename it to `.nix` thinking that is the convention.
- Safe modification: Document the underscore-prefix rule once, in `profiles/README.md`, and explain that `_example.nix.txt` only carries `.txt` because the file is not valid Nix until the user fills it in.
- Test coverage: None.

**Profile resolution falls back through multiple branches — MEDIUM:**
- Files: `public/_builder.nix:8-18`
- Why fragile: Five-way conditional (env var present / matching, `defaultProfile` set / matching, `personal` exists, single profile, empty). Each new branch grew with a 1.0.0 doc rewrite. The throw at the end mentions only env var + defaultProfile, not the `personal` fallback (the working-tree edit fixes this).
- Safe modification: Add an evaluation-time check that exactly one selection rule applies, or refactor into a small `lib.cabanashmul.resolveProfile` function with unit-style fixtures (still doable in pure Nix via `runTests`).
- Test coverage: None.

## Scaling Limits

**`profiles` attrset has no namespacing — LOW:**
- Current capacity: Any number of profiles, but each profile name becomes part of a `homeConfigurations` attribute (`${username}-${name}`).
- Limit: Two profiles named the same across `private/` and `profiles/` would collide silently because both write to `flake.cabanashmul.profiles.<name>` (module-system merge semantics would attempt to merge the two attrsets, often successfully but in unpredictable ways).
- Scaling path: Prefix or namespace private profiles (e.g. `flake.cabanashmul.profiles."work-acme"`), and warn in `private/README.md` against name collisions with `profiles/`.

## Dependencies at Risk

**`flake.lock` is from 2026-04-27 — LOW:**
- Risk: The lockfile predates the 1.0.0 release and has not been refreshed since the doc/UX work landed. nixpkgs `nixos-unstable`, home-manager, and agenix have all moved.
- Impact: Users who clone today get older pinned inputs than the maintainer is likely testing against. Stale `home-manager` could miss bug fixes used by `core.nix`'s `programs.ssh.enableDefaultConfig = false` (a relatively recent option).
- Migration plan: Run `nix flake update` regularly (monthly is reasonable for a starter template) and commit the resulting `flake.lock`. Consider adding a GitHub Actions workflow under `.github/workflows/` to open a PR on a schedule.

**Three first-party flake inputs (`zshmul`, `tshmux`, `shmulvim`) without revision pins — LOW:**
- Risk: These follow the same author's repos and track default branches. A breaking change in any of them (e.g. renaming `homeManagerModules.default`) breaks `cabanashmul` immediately for everyone running `nix flake update`.
- Files: `flake.nix:15-20`, `public/zshmul.nix:3`, `public/tshmux.nix:3`, `public/shmulvim.nix`
- Impact: Tightly-coupled family of flakes; any module-API change cascades.
- Migration plan: Coordinate releases across the family (zshmul / tshmux / shmulvim / cabanashmul) so `flake.lock` updates land together. Optionally add a CI smoke build in `.github/workflows/` that builds at least one `homeConfigurations.<user>-personal.activationPackage` against pinned inputs.

## Cross-Platform Gaps

**No Darwin (macOS) support — HIGH:**
- Problem: `flake.nix:25` declares `systems = [ "x86_64-linux" "aarch64-linux" ]`. No `x86_64-darwin` or `aarch64-darwin` entry, and `mkConfig` hard-codes `legacyPackages.x86_64-linux`. Home Manager itself supports Darwin standalone, so the gap is artificial.
- Files: `flake.nix:25`, `public/_builder.nix:22`, `public/_options.nix:5-7` (`context` enum is `desktop` / `server` / `wsl` only)
- Impact: A non-trivial Home Manager audience (developers on macOS) cannot use this starter as-is.
- Fix approach: Add `x86_64-darwin` and `aarch64-darwin` to `systems`. Replace the hard-coded `legacyPackages.x86_64-linux` with a per-system selection (see "Hard-coded `x86_64-linux`" above). Add a `"darwin"` member to the `context` enum or a `"macos"` value, and gate Linux-only packages (`wl-clipboard`, `xclip` in `public/zshmul.nix:17`) accordingly.

## Bootstrap / UX Friction

**`home-manager` itself is a separate prerequisite — MEDIUM:**
- Problem: README step 3 instructs `nix shell home-manager#home-manager` before `home-manager switch --impure --flake . -b backup`. New users have to grasp two top-level Nix invocations (`nix run`, `nix shell`) and one Home Manager invocation in the same session.
- Files: `README.md:106-115`, `README.md:165-167`
- Cause: Home Manager's standalone install model. The flake cannot install `home-manager` into the user's PATH before the first `switch` runs.
- Improvement path: Add a `nix run github:shmul95/cabanashmul#switch` app that wraps the entire `home-manager switch --impure --flake . -b backup` invocation against the locked Home Manager input, so the very first run is a single command.

**`--impure` framed as required, but feels surprising — LOW:**
- Problem: README step 3 has a note ("It's required, not a code smell") indicating that `--impure` is itself a UX smell that needed a defense.
- Files: `README.md:111-113`
- Improvement path: A pure entry point (see above) would let advanced users opt into pure builds and remove the apologia.

**README links a "Non-NixOS Shell Setup" section users must run manually — LOW:**
- Problem: After `home-manager switch`, users still have to add zsh to `/etc/shells`, `chsh`, log out, and log back in (`README.md:225-236`). The script in that section is copy-pastable but not automated.
- Files: `README.md:224-236`
- Improvement path: Add a `setup-shell` script (or a `--shell` flag to the existing `setup`) that performs the `/etc/shells` + `chsh` flow with the user's confirmation.

## Missing Critical Features

**No flake check / no CI build — MEDIUM:**
- Problem: `.github/workflows/` exists but contains nothing useful for verifying that the flake builds. There is no `nix flake check`, no smoke build of `homeConfigurations.<user>-personal.activationPackage`, no shellcheck on `scripts/*.sh`.
- Files: `.github/workflows/` (empty per `ls`), `flake.nix`
- Blocks: Catching regressions before tagging the next release. The 1.0.0 doc claims "the onboarding path has been validated end-to-end" but there is no automated proof of that.
- Improvement path: Add a workflow that, on PR and on push to `main`, runs `nix flake check`, builds at least one profile's `activationPackage` with a fake `USER` and `HOME`, and runs `shellcheck scripts/*.sh`.

**No automated tests for `_builder.nix`'s profile resolution — MEDIUM:**
- Problem: The five-way `activeName` conditional in `public/_builder.nix:8-18` is the heart of the project's UX, but there are no tests asserting its behavior across the five branches (env var matches / env var missing / `defaultProfile` matches / `personal` fallback / single profile).
- Blocks: Refactoring or simplifying the resolution logic safely.
- Improvement path: Add a `tests.nix` or `checks.nix` using `lib.runTests` to drive `cab.profiles` fixtures through a pure version of the resolver.

## Test Coverage Gaps

**Zero tests anywhere in the repo — MEDIUM:**
- What's not tested: Profile resolution, builder behavior, setup script (`scripts/setup.sh`), build-profiles discovery (`scripts/build-profiles.sh`), switch-profile activation (`scripts/switch-profile.sh`).
- Files: entire repo
- Risk: All bug fixes in this audit and any future refactor land without a safety net. The deprecation of `CABANASHMUL_PROFILE` cannot be verified to keep working until removed.
- Priority: MEDIUM — this is a starter template, not a runtime service, so test ROI is moderate, but profile resolution is the user-facing contract and deserves at least `lib.runTests` coverage.

**Shell scripts are not lint-checked — LOW:**
- What's not tested: `scripts/setup.sh`, `scripts/build-profiles.sh`, `scripts/switch-profile.sh`.
- Files: `scripts/*.sh`
- Risk: Quoting mistakes (already mitigated by `set -euo pipefail` and careful use of `"${VAR}"`) can still slip in. `setup.sh` reads from stdin without a TTY check.
- Priority: LOW. Add `shellcheck` as a single CI step.

---

*Concerns audit: 2026-05-07*
