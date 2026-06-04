{ inputs, config, ... }: let
  username = config.flake.cabanashmul.nixos.userName;
in {
  flake.cabanashmul.nixosModules.hermes = { config, ... }: {
    imports = [ inputs.hermes-agent.nixosModules.default ];

    services.hermes-agent = {
      enable = true;

      # Keep the CLI attached to the managed runtime instead of creating a
      # second ad-hoc ~/.hermes in the user session.
      addToSystemPackages = true;

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
  };
}
