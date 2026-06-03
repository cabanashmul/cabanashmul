{ ... }: {
  flake.cabanashmul.nixosModules.cabanashmul = { lib, pkgs, ... }: {
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

    networking.networkmanager.enable = lib.mkDefault true;

    services.openssh.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      git
      vim
      curl
    ];
  };
}
