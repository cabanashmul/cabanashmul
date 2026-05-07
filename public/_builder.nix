{ inputs, lib, config, ... }: let
  username      = let d = builtins.getEnv "USER"; in if d != "" then d else "your-username";
  homeDirectory = let d = builtins.getEnv "HOME"; in if d != "" then d else "/home/${username}";
  envProfile    = builtins.getEnv "CABANASHMUL_PROFILE";

  cab          = config.flake.cabanashmul;
  profileNames = lib.attrNames cab.profiles;
  activeName =
    if envProfile != "" then
      if cab.profiles ? ${envProfile} then envProfile
      else throw "cabanashmul: CABANASHMUL_PROFILE='${envProfile}' was requested but not found (have: ${lib.concatStringsSep ", " profileNames})"
    else if cab.defaultProfile != null then
      if cab.profiles ? ${cab.defaultProfile} then cab.defaultProfile
      else throw "cabanashmul: flake.cabanashmul.defaultProfile='${cab.defaultProfile}' was requested but not found (have: ${lib.concatStringsSep ", " profileNames})"
    else if cab.profiles ? personal then "personal"
    else if (lib.length profileNames) == 1 then lib.head profileNames
    else if profileNames == [] then "none"
    else throw "cabanashmul: set CABANASHMUL_PROFILE or flake.cabanashmul.defaultProfile (have: ${lib.concatStringsSep ", " profileNames}; 'personal' is used automatically when present)";

  mkConfig = name: profile:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = (lib.attrValues cab.homeModules) ++ [
        {
          home.username      = lib.mkDefault username;
          home.homeDirectory = lib.mkDefault homeDirectory;
          home.stateVersion  = lib.mkDefault "25.05";
          programs.home-manager.enable = true;
          nixpkgs.config.allowUnfree  = true;
        }
      ];
      extraSpecialArgs = {
        inherit inputs username homeDirectory;
        activeProfile = profile;
        context       = cab.context;
      };
    };
in {
  flake.homeConfigurations =
    (lib.mapAttrs' (name: profile:
      lib.nameValuePair "${username}-${name}" (mkConfig name profile)
    ) cab.profiles)
    // (let ap = if cab.profiles ? ${activeName} then cab.profiles.${activeName} else {}; in {
      "${username}" = mkConfig activeName ap;
    });

  flake.lib.mkHomeConfig = { extraModules ? [], extraSpecialArgs ? {} }:
    let ap = if cab.profiles ? ${activeName} then cab.profiles.${activeName} else {}; in
    mkConfig activeName ap;

  flake.lib.profileNamesStr =
    builtins.concatStringsSep " " profileNames;
}
