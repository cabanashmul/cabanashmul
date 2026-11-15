{ ... }: {
  flake.cabanashmul.homeModules.kitty = { lib, context, ... }: {
    programs.kitty = lib.mkIf (context == "desktop") {
      enable = true;
      settings = {
        font_family           = "JetBrainsMono Nerd Font";
        disable_ligatures     = "never";
        allow_remote_control   = "socket-only";
        listen_on              = "unix:$XDG_RUNTIME_DIR/kitty-vigil";
      };
    };
  };
}
