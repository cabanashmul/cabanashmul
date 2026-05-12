{ lib, ... }: {
  options.flake.cabanashmul = lib.mkOption {
    type = lib.types.submodule {
      options = {
        context = lib.mkOption {
          type    = lib.types.enum [ "desktop" "server" "wsl" ];
          default = "server";
        };
        defaultProfile = lib.mkOption {
          type    = lib.types.nullOr lib.types.str;
          default = null;
        };
        profiles = lib.mkOption {
          type    = lib.types.attrsOf lib.types.attrs;
          default = {};
        };
        homeModules = lib.mkOption {
          type    = lib.types.attrsOf lib.types.deferredModule;
          default = {};
        };
        overlays = lib.mkOption {
          type    = lib.types.listOf lib.types.unspecified;
          default = [];
          description = "nixpkgs overlays applied when instantiating pkgs for homeConfigurations.";
        };
      };
    };
    default = {};
    description = "cabanashmul configuration options merged across all public/ modules.";
  };
}
