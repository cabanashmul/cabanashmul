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
        # djinn.nvim: agenix-decrypted key -> env var (store holds only the command)
        if [ -r /run/agenix/djinn-deepseek ]; then
          export DEEPSEEK_API_KEY="$(cat /run/agenix/djinn-deepseek)"
        fi

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
