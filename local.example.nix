# Copy to local.nix (gitignored) and edit.
# Declares the machine context and, optionally, a non-personal default profile.
{ ... }: {
  flake.cabanashmul.context = "server"; # "server" | "wsl" | "desktop"

  # NixOS host settings. Keep the hostname at "cabanashmul" unless you also
  # rename the flake output in nixos/_options.nix.
  # flake.cabanashmul.nixos.userName = "shmul95";

  # Optional. If omitted, cabanashmul uses profiles.personal when present.
  # flake.cabanashmul.defaultProfile = "work";

  # Point GSD at the local vault you created with `init-vault`.
  # programs.gsd.vault.path = "/home/you/vault";
}
