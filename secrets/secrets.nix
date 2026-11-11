# Declare which SSH public keys can decrypt each secret.
# Run: nix run github:ryantm/agenix -- -e <file>.age
let
  me = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOceK0eVaktFCAcOBqUeGN5X9gj7izp7zxn2jBoJrGZC samuel.gross@epitech.eu";
in {
  "github_personal.age"     = { publicKeys = [ me ]; };
  "github_work.age"         = { publicKeys = [ me ]; };
  "git-email-personal.age"  = { publicKeys = [ me ]; };
  "git-email-work.age"      = { publicKeys = [ me ]; };

  # Hermes Agent ("creature") — API keys + Discord token
  "creature-env.age"        = { publicKeys = [ me ]; };

  # djinn.nvim — DeepSeek API key (exported as DEEPSEEK_API_KEY at shell init)
  "djinn-deepseek.age"      = { publicKeys = [ me ]; };
}
