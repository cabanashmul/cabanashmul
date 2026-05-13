{ inputs, ... }: {
  flake.cabanashmul.homeModules.gsd = { providers, ... }: {
    imports = [ inputs.get-shmul-done.homeManagerModules.default ];

    programs.gsd = {
      # Turn on the upstream get-shmul-done module by default.
      enable = true;

      # Install the runtimes GSD knows how to bootstrap in this repo.
      # Shared with shmulsidian via public/providers.nix.
      inherit providers;

      # Keep the full feature set enabled unless a local profile turns it down.
      minimal = false;
    };
  };
}
