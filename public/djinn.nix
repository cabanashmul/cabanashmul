{ inputs, ... }: {
  flake.cabanashmul.homeModules.djinn = { ... }: {
    imports = [ inputs.djinn.homeManagerModules.default ];

    # DeepSeek's Anthropic-compatible endpoint. The API key comes from the
    # environment at editor runtime (agenix-decrypted secret exported as
    # DEEPSEEK_API_KEY) — never from Nix, never from the store.
    programs.djinn = {
      enable      = true;
      model       = "deepseek-chat";
      base_url    = "https://api.deepseek.com/anthropic";
      api_key_env = "DEEPSEEK_API_KEY";
    };
  };
}
