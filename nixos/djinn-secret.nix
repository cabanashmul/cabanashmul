# djinn.nvim API key: agenix decrypts secrets/djinn-deepseek.age to
# /run/agenix/djinn-deepseek at activation. The value never enters the Nix
# store; the zsh `nvim` function injects it as DEEPSEEK_API_KEY for that
# process tree only (public/zshmul.nix), and djinn holds only the env var NAME.
{ inputs, config, ... }: let
  username = config.flake.cabanashmul.nixos.userName;
in {
  flake.cabanashmul.nixosModules.djinn-secret = { lib, ... }: {
    imports = [ inputs.agenix.nixosModules.default ];
    # Secrets are encrypted to the user's SSH key (same recipient as
    # secrets/secrets.nix), not the host keys — activation runs as root and
    # can read it. This replaces the host-key default, which could not
    # decrypt any of this repo's secrets.
    age.identityPaths = lib.mkAfter [
      "/home/${username}/.ssh/agenix_key"
    ];
    age.secrets.djinn-deepseek = {
      file  = ./../secrets/djinn-deepseek.age;
      owner = username;
      mode  = "0400";
    };
  };
}
