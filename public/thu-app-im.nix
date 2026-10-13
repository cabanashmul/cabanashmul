{ inputs, ... }: {
  flake.cabanashmul.homeModules.thu-app-im = { ... }: {
    imports = [ inputs.thu-app-im.homeManagerModules.default ];

    # Outillage de dev : Node 24 + Python/requests + tsd-dev.
    programs.tsdashboard.enable = true;
  };
}
