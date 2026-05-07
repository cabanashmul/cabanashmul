{ ... }: {
  perSystem = { pkgs, ... }:
    let
      initVaultScript = pkgs.writeShellApplication {
        name = "init-vault";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          export INIT_VAULT_TEMPLATE='${toString ../vault-template}'
          ${builtins.readFile ../scripts/init-vault.sh}
        '';
      };
    in {
      packages.init-vault = initVaultScript;
      apps.init-vault = {
        type = "app";
        program = "${initVaultScript}/bin/init-vault";
      };
    };
}
