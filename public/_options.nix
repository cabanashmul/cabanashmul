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
        providers = lib.mkOption {
          type    = lib.types.listOf lib.types.str;
          default = [];
          description = "AI providers shared across modules (e.g. shmulsidian, get-shmul-done).";
        };
      };
    };
    default = {};
    description = "cabanashmul configuration options merged across all public/ modules.";
  };
}
