{ inputs, ... }: {
  # cabanashmul.shelp — opt-in home-manager module for the shelp CLI.
  # Mirrors the pattern used by cabanashmul.gsd (see public/get-shmul-done.nix).
  #
  # Usage in a profile:
  #   cabanashmul.shelp.enable = true;
  #
  # This adds the shelp binary to home.packages so `shelp` is available in PATH.
  # shelp is the offline terminal doc browser for the cabanashmul ecosystem.
  #
  # Tested: 2026-05-10 — module wired; home-manager switch verification
  # pending until cabanashmul/shelp is published to GitHub as a real repo.
  # Verified on: x86_64-linux (local cargo build + nix build pass)

  flake.cabanashmul.homeModules.shelp = { pkgs, lib, config, ... }:
    let
      cfg = config.cabanashmul.shelp;
    in {
      options.cabanashmul.shelp = {
        enable = lib.mkEnableOption "shelp offline terminal doc browser";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          inputs.shelp.packages.${pkgs.system}.default
        ];
      };
    };
}
