{ lib, ... }: {
  options.flake.cabanashmul.nixos = lib.mkOption {
    type = lib.types.submodule {
      options = {
        hostName = lib.mkOption {
          type        = lib.types.str;
          default     = "cabanashmul";
          description = "The NixOS hostname exported as flake.nixosConfigurations.<hostName>.";
        };
        userName = lib.mkOption {
          type        = lib.types.str;
          default     = "shmul95";
          description = "The primary local user that Home Manager will manage.";
        };
        system = lib.mkOption {
          type        = lib.types.str;
          default     = "x86_64-linux";
          description = "The target NixOS system architecture.";
        };
        stateVersion = lib.mkOption {
          type        = lib.types.str;
          default     = "25.05";
          description = "NixOS system.stateVersion.";
        };
        homeStateVersion = lib.mkOption {
          type        = lib.types.str;
          default     = "25.05";
          description = "Home Manager home.stateVersion.";
        };
        timeZone = lib.mkOption {
          type        = lib.types.str;
          default     = "Europe/Paris";
          description = "System time zone.";
        };
        locale = lib.mkOption {
          type        = lib.types.str;
          default     = "en_US.UTF-8";
          description = "System locale.";
        };
      };
    };
    default = {};
    description = "NixOS host settings for cabanashmul.";
  };
}
