# Copy to local.nix (gitignored) and edit.
# Declares the machine context and, optionally, a non-personal default profile.
{ ... }: {
  flake.cabanashmul.context = "server"; # "server" | "wsl" | "desktop"

  # Optional. If omitted, cabanashmul uses profiles.personal when present.
  # flake.cabanashmul.defaultProfile = "work";
}
