{ inputs, config, ... }: {
  flake.cabanashmul.homeModules.gsd = { lib, ... }: {
    imports = lib.optionals config.flake.cabanashmul.gsd.enable [
      inputs.get-shmul-done.homeManagerModules.default
    ];
  };
}
