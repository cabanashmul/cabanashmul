{ inputs, ... }: {
  flake.cabanashmul.homeModules.vim-module = { ... }: {
    imports = [ inputs.vim-module.homeManagerModules.default ];

    programs.vim-module = {
      enable = true;
      model  = "claude-haiku-4-5";
    };
  };
}
