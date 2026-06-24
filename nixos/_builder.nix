{ inputs, lib, config, ... }: let
  cab           = config.flake.cabanashmul;
  hostConfig    = cab.nixos;
  username      = hostConfig.userName;
  homeDirectory  = "/home/${username}";
  envProfile    = builtins.getEnv "CABANASHMUL_PROFILE";
  profileNames  = lib.attrNames cab.profiles;
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
  activeProfile =
    if cab.profiles ? ${activeName} then cab.profiles.${activeName} else {};
  homeModules =
    (lib.attrValues cab.homeModules) ++ [
      {
        home.username      = lib.mkDefault username;
        home.homeDirectory = lib.mkDefault homeDirectory;
        home.stateVersion  = lib.mkDefault hostConfig.homeStateVersion;
        programs.home-manager.enable = true;
      }
    ];
in {
  flake.nixosConfigurations.${hostConfig.hostName} = inputs.nixpkgs.lib.nixosSystem {
    system = hostConfig.system;
    specialArgs = {
      inherit inputs username homeDirectory activeProfile;
      context   = cab.context;
      providers = cab.providers;
    };
    modules =
      (lib.optionals (builtins.pathExists ./hardware-configuration.nix) [ ./hardware-configuration.nix ])
      ++ (lib.attrValues cab.nixosModules)
      ++ [
        ({ ... }: {
          nixpkgs.hostPlatform = hostConfig.system;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          networking.hostName = hostConfig.hostName;
          time.timeZone = hostConfig.timeZone;
          i18n.defaultLocale = hostConfig.locale;

          users.users.${username} = {
            isNormalUser = true;
            home = homeDirectory;
            createHome = true;
            extraGroups = [ "wheel" "networkmanager" ];
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs username homeDirectory activeProfile;
              context   = cab.context;
              providers = cab.providers;
            };
            users.${username} = {
              imports = homeModules;
            };
          };

          system.stateVersion = hostConfig.stateVersion;
        })
        inputs.home-manager.nixosModules.home-manager
      ];
  };
}
