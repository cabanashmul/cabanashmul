# profiles

This directory holds per-identity profile definitions such as `personal`, `work`, or any other context where Git and SSH settings should differ.

These files are imported automatically when they exist.

## The Default Profile

The normal starting point is `profiles/personal.nix`.

If `personal` exists, `home-manager switch --impure --flake .` uses it by default even without `local.nix`.

## Start From The Example

Use [`_example.nix.txt`](./_example.nix.txt) as the template for a real profile file:

- `profiles/personal.nix`
- `profiles/work.nix`

Example:

```nix
{ ... }: {
  flake.cabanashmul.profiles.personal = {
    git.settings.user = {
      name = "Your Name";
      email = "you@example.com";
    };

    ssh.matchBlocks."github.com" = {
      identityFile = "~/.ssh/github_personal";
    };
  };
}
```

## What A Profile Affects

The public [`core.nix`](../public/core.nix) module consumes the active profile and wires:

- `programs.git.settings`
- `programs.ssh.matchBlocks`

You can also reference secrets instead of plain strings, for example with agenix-managed paths.

## How Profile Selection Works

The active profile is chosen in this order:

1. `CABANASHMUL_PROFILE`
2. `flake.cabanashmul.defaultProfile` from `local.nix`
3. `personal`, if it exists
4. the only profile, if there is exactly one

Examples:

```bash
home-manager switch --impure --flake .
```

```bash
CABANASHMUL_PROFILE=work home-manager switch --impure --flake .
```

The flake exposes:

- `.#"$USER"` for the active/default profile
- `.#"$USER"-<profile>` for each named profile

## Do You Need More Than Personal?

No. Extra profiles are optional.

Create more profiles only if you want different identities, for example:

- personal Git identity vs work Git identity
- different SSH keys per GitHub account
- different settings for different machines or roles
