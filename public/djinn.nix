{ inputs, ... }: {
  flake.cabanashmul.homeModules.djinn = { ... }: {
    imports = [ inputs.djinn.homeManagerModules.default ];

    programs.djinn = {
      enable = true;
      model  = "claude-haiku-4-5";
    };
  };
}
