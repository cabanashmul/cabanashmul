{ inputs, config, ... }: let
  username = config.flake.cabanashmul.nixos.userName;
in {
  flake.cabanashmul.nixosModules.hermes = { config, pkgs, ... }: {
    imports = [ inputs.hermes-agent.nixosModules.default ];

    services.hermes-agent = {
      enable = true;

      # Keep the CLI attached to the managed runtime instead of creating a
      # second ad-hoc ~/.hermes in the user session.
      addToSystemPackages = true;

      # Include Discord/Telegram/Slack dependencies in the sealed Nix venv.
      # On NixOS this is the documented equivalent of the `#messaging` package.
      extraDependencyGroups = [ "messaging" ];

      # Container mode is the good default once you want Hermes to run as a
      # background service and keep its own long-lived writable runtime.
      container = {
        enable = true;
        hostUsers = [ username ];
      };

      # Fill these in once you have real credentials and model defaults.
      # The docs recommend keeping secrets in environmentFiles and authFile.
      #
      # settings = {
      #   model.default = "openrouter/your-model";
      # };
      #
      # environmentFiles = [
      #   config.age.secrets."hermes-env".path
      # ];
      #
      # authFile = config.age.secrets."hermes-auth".path;
    };

    # Keep the personal shmulsidian vault writable by the hermes user so the
    # memory provider can persist notes during tool calls.
    systemd.tmpfiles.rules = [
      "d /home/${username}/shmulsidian 0755 ${username} ${username} -"
      "Z /home/${username}/shmulsidian 0755 ${username} ${username} -"
    ];
  };
}
