# nixos/memtide-hermes.nix — Hermes Agent for MemTide project
#
# Runs hermes-agent in container mode with:
# - hermes-shmulsidian memory plugin (vault search/read/create)
# - memtide-vault mounted as the knowledge base
# - memtide-dev workspace mounted for code context
# - Discord bot integration
# - agenix secrets for API keys
#
# Usage in your NixOS config:
#   imports = [ cabanashmul.nixosModules.memtide-hermes ];
#
# Override paths if needed:
#   cabanashmul.memtide.vaultPath = "/home/me/memtide-vault";
#   cabanashmul.memtide.workspacePath = "/home/me/memtide-dev";
{ inputs, config, ... }: let
  username = config.flake.cabanashmul.nixos.userName;
  system = config.flake.cabanashmul.nixos.system;

  hermesShmulsidian = inputs.hermes-shmulsidian.packages.${system}.default;

  # Container mount points
  vaultMountPoint = "/data/vault";
  workspaceMountPoint = "/data/memtide-dev";
in {
  # Options for path configuration
  options.flake.cabanashmul.memtide = with inputs.nixpkgs.lib; {
    vaultPath = mkOption {
      type = types.str;
      default = "/home/${username}/Repositories/memtide-dev/repos/memtide-vault";
      description = "Host path to the memtide-vault directory.";
    };
    workspacePath = mkOption {
      type = types.str;
      default = "/home/${username}/Repositories/memtide-dev";
      description = "Host path to the memtide-dev workspace.";
    };
  };

  config.flake.cabanashmul.nixosModules.memtide-hermes = { config, lib, pkgs, ... }: let
    cfg = config.flake.cabanashmul.memtide;
  in {
    imports = [
      inputs.agenix.nixosModules.default
      inputs.hermes-agent.nixosModules.default
      inputs.hermes-shmulsidian.nixosModules.default
    ];

    # Agenix secrets
    age.secrets.hermes-env = {
      file = ./../secrets/hermes-env.age;
      owner = "hermes";
      group = "hermes";
      mode = "0440";
    };

    age.secrets.discord-bot = {
      file = ./../secrets/discord-bot.age;
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
        config.age.secrets.hermes-env.path
        config.age.secrets.discord-bot.path
      ];

      # Env var for the shmulsidian plugin
      environment = {
        SHMULSIDIAN_VAULT_PATH = vaultMountPoint;
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

        # Discord — declarative, no interactive setup needed
        discord.enabled = true;
      };

      # Plugin: shmulsidian memory provider
      extraPlugins = [ hermesShmulsidian ];

      # Container mode
      container = {
        enable = true;
        hostUsers = [ username ];

        # Mount vault (read-only) and workspace (read-only)
        extraVolumes = [
          "${cfg.vaultPath}:${vaultMountPoint}:ro"
          "${cfg.workspacePath}:${workspaceMountPoint}:ro"
        ];
      };
    };
  };
}
