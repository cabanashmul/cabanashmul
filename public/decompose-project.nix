{ inputs, ... }: {
  # cabanashmul.decompose-project — home-manager module installing the
  # /decompose-project and /create-service Claude Code skills.
  #
  # Source: github.com/cabanashmul/decompose-project
  #
  # Enabled by default. To opt out, add to a profile or local.nix:
  #   cabanashmul.decompose-project.enable = false;
  #
  # When enabled, drops the two SKILL.md files into ~/.claude/skills/,
  # making `/decompose-project` and `/create-service` available in any
  # Claude Code session.

  flake.cabanashmul.homeModules.decompose-project = { lib, config, ... }:
    let
      cfg = config.cabanashmul.decompose-project;
      src = inputs.decompose-project;
    in {
      options.cabanashmul.decompose-project = {
        # Enabled by default — override with `cabanashmul.decompose-project.enable = false;`
        # in a profile or local.nix to opt out.
        enable = (lib.mkEnableOption
          "claude skills for bootstrapping multi-repo projects (/decompose-project and /create-service)")
          // { default = true; };
      };

      config = lib.mkIf cfg.enable {
        home.file.".claude/skills/decompose-project/SKILL.md".source =
          "${src}/skills/decompose-project/SKILL.md";
        home.file.".claude/skills/create-service/SKILL.md".source =
          "${src}/skills/create-service/SKILL.md";
      };
    };
}
