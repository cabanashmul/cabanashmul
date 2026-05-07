# External Integrations

**Analysis Date:** 2026-05-07

## APIs & External Services

**GitHub (flake input source — public HTTPS, no auth):**
- `nixpkgs` — `github:NixOS/nixpkgs/nixos-unstable` (declared in `flake.nix`).
- `flake-parts` — `github:hercules-ci/flake-parts`.
- `import-tree` — `github:vic/import-tree`.
- `home-manager` — `github:nix-community/home-manager`.
- `agenix` — `github:ryantm/agenix`.
- `zshmul` — `github:shmul95/zshmul`.
- `tshmux` — `github:shmul95/tshmux`.
- `shmulvim` — `github:shmul95/shmulvim`.
- All resolved by `nix flake update` against `github.com`'s public archive endpoint. No tokens required for fetching. Pinned revisions live in `flake.lock`.

**GitHub (template clone in setup):**
- `scripts/setup.sh` clones `${CABANASHMUL_TEMPLATE_URL:-https://github.com/shmul95/cabanashmul.git}`. HTTPS is the default per the 1.0.0 changelog entry in `CHANGELOG.md` and the README troubleshooting section. Override the env var to use SSH (`git+ssh://`).

**GitHub (optional private repo creation):**
- `scripts/setup.sh` `maybe_create_private_origin` calls `gh repo create "$(basename "$PWD")" --private --source=. --remote=origin --push` when the user answers `y` at the prompt. This requires:
  - `gh` CLI installed (declared as a `runtimeInput` in `public/setup.nix`).
  - The user's existing `gh auth` session — the script does not handle auth itself.
  - Skipped silently if an `origin` remote already exists.

**Private SSH-gated GitHub repos (optional, opt-in):**
- Pattern documented in `private-inputs.example.nix` and `private/README.md`. Users add entries like:
  ```nix
  shmulcode = {
    url = "git+ssh://git@github.com/shmul95/shmulcode";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```
  directly to the `inputs` attrset in `flake.nix`, then consume them from a module under `private/`.
- Authentication: standard `~/.ssh/config` + ssh-agent. The flake itself does not provide credentials.

**Sibling family Home Manager modules (consumed via flake inputs, not network APIs at runtime):**
- `inputs.zshmul.homeManagerModules.default` — used by `public/zshmul.nix`.
- `inputs.tshmux.homeManagerModules.default` — used by `public/tshmux.nix`.
- `inputs.shmulvim.homeManagerModules.default` — used by `public/shmulvim.nix`.

**No third-party HTTP APIs.** Grepping the public modules and profile example surfaces no Stripe, AWS, Supabase, OpenAI, or similar SDK usage. The only outbound network traffic is `nix` fetching flake inputs from `github.com` and (during `setup`) `git clone` over HTTPS.

## Data Storage

**Databases:**
- None. This is a Home Manager configuration repo; there is no application database.

**File Storage:**
- Local filesystem only.
- Nix store: `/nix/store/...` for all built packages and home generations (system-managed).
- Prebuilt profile activation packages: `${XDG_DATA_HOME:-$HOME/.local/share}/cabanashmul/result-<profile>` symlinks, written by `scripts/build-profiles.sh` and read by `scripts/switch-profile.sh`.
- A symlinked `result` in the repo root (gitignored via `.gitignore`) is created by ad-hoc `nix build` invocations.

**Caching:**
- Nix's content-addressed store and per-input narHash entries in `flake.lock` act as the build cache. No application-level cache.
- The `build-profiles` / `switch-profile` pair functions as a profile-activation cache: prebuild once into `$XDG_DATA_HOME/cabanashmul/`, then activate the cached result with no re-evaluation.

## Authentication & Identity

**Auth Provider:**
- None for the flake/runtime itself.
- Per-profile Git/SSH identity is set by `flake.cabanashmul.profiles.<name>`:
  - `git.settings.user.{name,email}` → wired into `programs.git.settings` by `public/core.nix`.
  - `ssh.matchBlocks.<host>.identityFile` → wired into `programs.ssh.matchBlocks` (with `enableDefaultConfig = false`) by `public/core.nix`.
- The active profile is chosen at evaluation time in `public/_builder.nix` from `CABANASHMUL_PROFILE` → `flake.cabanashmul.defaultProfile` → `personal` → the lone profile.

**SSH key conventions (per `profiles/_example.nix.txt` and `secrets/README.md`):**
- Plain path form: `identityFile = "~/.ssh/github_<name>";`.
- Agenix-managed form: `identityFile = config.age.secrets.github_<name>.path;`.

## Monitoring & Observability

**Error Tracking:**
- None.

**Logs:**
- Standard Bash output from `scripts/setup.sh`, `scripts/build-profiles.sh`, `scripts/switch-profile.sh` (stderr for errors; stdout for progress lines).
- Home Manager's own activation log (`home-manager generations` exposes prior generations for rollback per the `README.md` "Daily loop" section).

## CI/CD & Deployment

**Hosting:**
- Not applicable — this is consumed locally per user via `home-manager switch`. The repo is published on GitHub at `github.com/shmul95/cabanashmul`.

**CI Pipeline:**
- `.github/workflows/` exists but is empty — no GitHub Actions workflow files are present in the repo.
- No `flake.checks` output, no `nix flake check` integration, no test runner.

**Distribution:**
- Users invoke `nix run github:shmul95/cabanashmul#setup` (defined in `public/setup.nix` as `apps.setup` via `flake-parts`'s `perSystem`). The setup app clones the template, normalizes the `template`/`origin` remotes, and creates `profiles/personal.nix` + `local.nix`.

## Environment Configuration

**Read by Nix evaluation (`public/_builder.nix` via `builtins.getEnv`):**
- `USER` — required for `home.username` and `homeConfigurations` attribute naming.
- `HOME` — required for `home.homeDirectory`.
- `CABANASHMUL_PROFILE` — deprecated but still honored; selects the active profile.

**Read by shell scripts:**
- `CABANASHMUL_TEMPLATE_URL` — `scripts/setup.sh` clone URL override (default `https://github.com/shmul95/cabanashmul.git`).
- `CABANASHMUL_DIR` — `scripts/build-profiles.sh` flake directory override (default `$PWD`).
- `XDG_DATA_HOME` — used by `scripts/build-profiles.sh` and `scripts/switch-profile.sh` (default `$HOME/.local/share`).

**Secrets location:**
- No `.env`, `.envrc`, or secret file is committed. `.gitignore` keeps `local.nix`, `private/*` (except `private/README.md`), `profiles/*.nix`, `private-inputs.nix`, and `result*` out of the repo.
- Encrypted secrets (when `agenix` is opted into) live as `*.age` files referenced from `secrets/secrets.nix`. The recipient map declares one or more SSH public keys per file:
  ```nix
  "github_personal.age" = { publicKeys = [ me ]; };
  ```
  Encrypted files are edited via `nix run github:ryantm/agenix -- -e <file>.age` (per the comment in `secrets/secrets.nix`).
- Profile files reference decrypted paths through `config.age.secrets.<name>.path` (see `profiles/_example.nix.txt`).

## Webhooks & Callbacks

**Incoming:**
- None.

**Outgoing:**
- None.

## Age / SSH Key Handling

- Recipients are SSH public keys (`ssh-ed25519 ...`) declared in `secrets/secrets.nix`. The placeholder `me = "ssh-ed25519 AAAA_REPLACE_ME"` must be replaced with the output of `cat ~/.ssh/id_ed25519.pub` per the file's own comment.
- `agenix` is wired in as `inputs.agenix` in `flake.nix` with `inputs.nixpkgs.follows = "nixpkgs"`, but the starter does not enable an `age` Home Manager module by default; users opt in by adding their own module under `public/` or `private/` and referencing `config.age.secrets.<name>.path` from a profile.
- `sops` is not used. There is no `.sops.yaml` or sops-nix input. Secret handling is age-only via `agenix`.

---

*Integration audit: 2026-05-07*
