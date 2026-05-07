{ ... }: {
  flake.cabanashmul.homeModules.packages = { pkgs, lib, context, ... }: {
    home.packages = [
      (pkgs.writeShellApplication {
        name           = "build-profiles";
        runtimeInputs  = [ pkgs.coreutils pkgs.nix ];
        text           = builtins.readFile ../scripts/build-profiles.sh;
      })
      (pkgs.writeShellApplication {
        name           = "switch-profile";
        runtimeInputs  = [ pkgs.coreutils ];
        text           = builtins.readFile ../scripts/switch-profile.sh;
      })
      (pkgs.writeShellApplication {
        name           = "update-cabanashmul";
        runtimeInputs  = [ pkgs.coreutils pkgs.git ];
        text           = builtins.readFile ../scripts/update-cabanashmul.sh;
      })
      (pkgs.writeShellApplication {
        name           = "init-vault";
        runtimeInputs  = [ pkgs.coreutils ];
        text           = ''
          export INIT_VAULT_TEMPLATE='${toString ../vault-template}'
          ${builtins.readFile ../scripts/init-vault.sh}
        '';
      })
    ] ++ lib.optionals (context == "desktop") (with pkgs; [ discord firefox kitty ]);
  };
}
