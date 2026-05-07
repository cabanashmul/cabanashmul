# secrets

This directory is for agenix secret metadata.

It is optional.

If you are happy keeping plain values in `profiles/*.nix` or using normal files under `~/.ssh`, you do not need any of this.

## What Lives Here

[`secrets.nix`](./secrets.nix) declares which SSH public keys are allowed to decrypt each secret.

Example shape:

```nix
let
  me = "ssh-ed25519 AAAA_REPLACE_ME";
in {
  "github_personal.age" = { publicKeys = [ me ]; };
}
```

## Typical Workflow

1. Put your SSH public key in [`secrets.nix`](./secrets.nix).
2. Create or edit encrypted secret files with agenix.
3. Reference the resulting secret paths from profile files under [`profiles/`](../profiles/README.md).

The profile example supports patterns like:

- Git email from a secret path
- SSH identity file from a secret path

The comment in [`secrets.nix`](./secrets.nix) shows the agenix edit command.
