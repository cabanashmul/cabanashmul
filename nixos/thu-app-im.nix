# nixos/thu-app-im.nix — Tsinghua Dashboard en nixos-container (cookie de session
# 网络学堂, clé Anthropic et script Python isolés de l'hôte).
{ inputs, config, ... }: let
  username = config.flake.cabanashmul.nixos.userName;
in {
  flake.cabanashmul.nixosModules.thu-app-im = { ... }: {
    imports = [ inputs.thu-app-im.nixosModules.default ];

    services.tsdashboard = {
      enable = true;
      # Adapter ces chemins à la machine (dossier des cours + script copié du PC).
      tsinghuaRoot = "/home/${username}/Tsinghua";
      syncScript   = "/home/${username}/tsinghua-dashboard/sync/thu_learn_sync.py";
      # environmentFile → câbler sur un secret agenix (cf. creature-env.nix) ensuite.
    };
  };
}
