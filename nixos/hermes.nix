# nixos/hermes.nix — Hermes Agent ("creature") for MemTide
#
# Runs hermes-agent in container mode with:
# - hermes-shmulsidian memory plugin (vault search/read/create)
# - memtide-dev workspace mounted (vault is nested inside at repos/memtide-vault)
# - Discord bot integration (@creature)
# - agenix secrets for API keys
#
# Secrets needed (in creature-env.age):
#   XIAOMI_API_KEY       — MiMo model provider
#   DISCORD_BOT_TOKEN    — Discord bot
#
# The agent searches the vault via shmulsidian tools and can read code
# from the mounted workspace. Interact via Discord: @creature <question>
{ inputs, config, ... }: let
  username = config.flake.cabanashmul.nixos.userName;
  system = config.flake.cabanashmul.nixos.system;

  hermesShmulsidian = inputs.hermes-shmulsidian.packages.${system}.default;

  # Single mount — vault lives inside at repos/memtide-vault
  workspaceMount = "/data/memtide-dev";
  vaultPath = "${workspaceMount}/repos/memtide-vault";
in {
  flake.cabanashmul.nixosModules.hermes = { config, lib, pkgs, ... }: {
    imports = [
      inputs.agenix.nixosModules.default
      inputs.hermes-agent.nixosModules.default
      inputs.hermes-shmulsidian.nixosModules.default
    ];

    # Agenix secrets
    age.secrets.creature-env = {
      file = ./../secrets/creature-env.age;
      owner = "hermes";
      group = "hermes";
      mode = "0440";
    };

    # Host user access
    users.users.${username}.extraGroups = [ "hermes" ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;

      # Secrets
      environmentFiles = [
        config.age.secrets.creature-env.path
      ];

      # Env vars for the shmulsidian plugin
      environment = {
        SHMULSIDIAN_VAULT_PATH = vaultPath;
      };

      # Declarative config
      settings = {
        model = {
          provider = "xiaomi";
          default = "mimo-v2.5-pro";
        };

        memory.provider = "shmulsidian";

        display = {
          interface = "tui";
          skin = "slate";
        };

        approvals.mode = "smart";
        agent.tool_use_enforcement = true;

        # Discord — declarative
        discord.enabled = true;
      };

      # Plugin: shmulsidian memory provider
      extraPlugins = [ hermesShmulsidian ];

      # Container mode
      container = {
        enable = true;
        hostUsers = [ username ];

        # Mount the whole workspace (vault is inside at repos/memtide-vault)
        extraVolumes = [
          "/home/${username}/Repositories/memtide-dev:${workspaceMount}:ro"
        ];
      };
    };
  };
}
