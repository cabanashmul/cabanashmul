# shmulcode — provider-multiplexed Claude Code launchers.
#
# One command per provider; the only difference is the env file. The launchers
# exec the claude-code binary supplied by the shmulcode flake (absolute store
# path), so nothing here depends on claude being on PATH.
#
# Secrets stay in agenix and are referenced by RUNTIME PATH only — the path
# string is baked into the wrapper, never the contents. No secret value ever
# reaches the Nix store.
#
# Owner steps before activation (see shmulcode's docs/CONSUMER-MIGRATION.md):
#   agenix -e secrets/mimocode-env.age
#   agenix -e secrets/deepcode-env.age
#   agenix -e secrets/grokcode-env.age
# then `home-manager build --impure` and finally `home-manager switch --impure`.
{ inputs, ... }: {
  flake.cabanashmul.homeModules.shmulcode = { config, ... }: {
    imports = [ inputs.shmulcode.homeManagerModules.default ];

    programs.shmulcode.instances = {
      mimocode = {
        enable = true;
        envFile = config.age.secrets."mimocode-env".path;
      };
      deepcode = {
        enable = true;
        envFile = config.age.secrets."deepcode-env".path;
      };
      grokcode = {
        enable = true;
        envFile = config.age.secrets."grokcode-env".path;
      };
    };
  };
}
