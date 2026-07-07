# Declare which SSH public keys can decrypt each secret.
# Run: nix run github:ryantm/agenix -- -e <file>.age
let
  # Replace with the output of: cat ~/.ssh/id_ed25519.pub
  me = "ssh-ed25519 AAAA_REPLACE_ME";
in {
  "github_personal.age"     = { publicKeys = [ me ]; };
  "github_work.age"         = { publicKeys = [ me ]; };
  "git-email-personal.age"  = { publicKeys = [ me ]; };
  "git-email-work.age"      = { publicKeys = [ me ]; };

  # Hermes Agent ("creature") — API keys + Discord token
  "creature-env.age"        = { publicKeys = [ me ]; };
}
