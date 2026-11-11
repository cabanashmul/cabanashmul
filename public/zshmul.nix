{ inputs, ... }: {
  flake.cabanashmul.homeModules.zshmul = { pkgs, ... }: {
    imports = [ inputs.zshmul.homeManagerModules.default ];

    programs.zshmul = {
      enable          = true;
      installPackage  = true;
      autoStartTshmux = true;

      aliases = {
        l  = "ls -la";
        lg = "lazygit";
        nd = "nix develop";
      };

      extraPackages = with pkgs; [
        lazygit bat tree xclip wl-clipboard ripgrep fd gh
      ];

      sessionVariables = {
        EDITOR                     = "nvim";
        VIRTUAL_ENV_DISABLE_PROMPT = "1";
        HYPHEN_INSENSITIVE         = "true";
        SHELL                      = "${pkgs.zsh}/bin/zsh";
      };

      prompt = {
        layout       = "singleline";
        symbol       = "$";
        arrowSymbol  = "->";
        relativePath = "adaptive";
        cursor       = "terminal";
      };

      ohMyZshPlugins = [ "git" "z" ];

      extraInitContent = ''
        # djinn.nvim: the DeepSeek key is scoped to nvim's process tree only —
        # never exported into the interactive shell (same idea as deepcode's
        # wrapper: the secret exists for the launched program, not the session).
        nvim() {
          if [ -r /run/agenix/djinn-deepseek ]; then
            DEEPSEEK_API_KEY="$(cat /run/agenix/djinn-deepseek)" command nvim "$@"
          else
            command nvim "$@"
          fi
        }

        export NVM_DIR="$HOME/.nvm"
        if [ -s "$NVM_DIR/nvm.sh" ]; then
          . "$NVM_DIR/nvm.sh"
        fi
        if [ -s "$NVM_DIR/bash_completion" ]; then
          . "$NVM_DIR/bash_completion"
        fi
      '';
    };
  };
}
