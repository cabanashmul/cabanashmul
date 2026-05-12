{ inputs, ... }: {
  # Inject shmulistan-mcp into pkgs for x86_64-linux (matches _builder.nix target system).
  flake.cabanashmul.overlays = [ (inputs.shmulistan.lib.mkOverlay "x86_64-linux") ];

  flake.cabanashmul.homeModules.shmulistan = { config, lib, ... }: {
    imports = [ inputs.shmulistan.homeManagerModules.default ];

    services.shmulistan = {
      enable = true;
      vaultPath = "${config.home.homeDirectory}/shmulistan";
      publishIdentity = {
        email = lib.mkDefault "operator@example.com";
        name  = lib.mkDefault config.home.username;
      };
      hooks = {
        sessionStart.enable = true;
        stop.enable         = true;
      };
    };
  };
}
