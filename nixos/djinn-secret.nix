# djinn.nvim API key: agenix decrypts secrets/djinn-deepseek.age to
# /run/agenix/djinn-deepseek at activation. The value never enters the Nix
# store; the shell exports it as DEEPSEEK_API_KEY (public/zshmul.nix), and
# djinn holds only that env var NAME (programs.djinn.api_key_env).
{ inputs, ... }: {
  flake.cabanashmul.nixosModules.djinn-secret = { ... }: {
    imports = [ inputs.agenix.nixosModules.default ];
    age.secrets.djinn-deepseek = {
      file  = ./../secrets/djinn-deepseek.age;
      owner = "shmul95";
      mode  = "0400";
    };
  };
}
