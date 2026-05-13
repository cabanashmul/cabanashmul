# Shared AI providers list — consumed by both public/shmulsidian.nix and
# public/get-shmul-done.nix via `inherit (self.cabanashmul) providers`.
# Override per-profile with `flake.cabanashmul.providers = …` if needed.
{ ... }: {
  flake.cabanashmul.providers = [ "claude-code" "codex" "copilot" ];
}
