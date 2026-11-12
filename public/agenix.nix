# Home-manager-level agenix: secrets for user-session CLI tools (deepcode,
# mimocode, djinn, ...). System daemons (hermes-agent) use NixOS-level
# agenix instead — see nixos/hermes.nix — because they need secrets at
# system activation; these activate with the user's own session/key and
# never require a reboot.
{ inputs, ... }: {
  flake.cabanashmul.homeModules.agenix = { config, ... }: {
    imports = [ inputs.agenix.homeManagerModules.default ];

    age.identityPaths = [ "${config.home.homeDirectory}/.ssh/agenix_key" ];

    age.secrets = {
      "djinn-deepseek" = { file = ../secrets/djinn-deepseek.age; mode = "600"; };
    };
  };
}
