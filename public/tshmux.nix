{ inputs, ... }: {
  flake.cabanashmul.homeModules.tshmux = { ... }: {
    imports = [ inputs.tshmux.homeManagerModules.default ];

    programs.tshmux = {
      enable               = true;
      installPackage       = true;
      setAsDefaultTmux     = true;
      enableShellIntegration = true;
      enableMouse          = true;
      enableViCopyMode     = true;
      enableSessionRestore = true;

      clipboard.enable = true;

      status.position = "top";
      status.left     = "#[fg=#{@color-yellow},bold]\\[#S\\]#[fg=#{@color-gray-light},bold] | ";
      status.right    = "";

      theme = {
        yellow     = "#FFDF32";
        black      = "#000000";
        grayLight  = "#D8DEE9";
        grayMedium = "#ABB2BF";
        grayDark   = "#3B4252";
      };

      extraConfig = ''
        # Put extra tmux commands here.
        # Vigil (Phase 1, infrastructure prerequisite): required for the OSC 99
        # kitty-notification focus-pull fallback (Phase 6) to reach the outer
        # kitty terminal from inside a tmux pane. Security tradeoff recorded in
        # vigil's PROJECT.md Key Decisions table (single-user, local-socket-only
        # exposure — see Pitfall 11 in vigil's .planning/research/PITFALLS.md).
        set -g allow-passthrough on
      '';
    };
  };
}
