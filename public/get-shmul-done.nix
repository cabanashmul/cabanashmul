{ inputs, ... }: {
  flake.cabanashmul.homeModules.gsd = { ... }: {
    imports = [ inputs.get-shmul-done.homeManagerModules.default ];

    programs.gsd = {
      # Turn on the upstream get-shmul-done module by default.
      enable = true;

      # Install the runtimes GSD knows how to bootstrap in this repo.
      providers = [ "claude-code" "codex" "copilot" ];

      # Keep the full feature set enabled unless a local profile turns it down.
      minimal = false;

      # Vault integration is part of the default module so the user can
      # discover and override the injected instructions in one place.
      vault = {
        enable = true;

        # Put personal policy here if you want it managed by this default
        # module. Local/profile files can override or replace it.
        injectInstructions.preamble = ''
          # Personal policy
          # ...
        '';
      };
    };
  };
}
