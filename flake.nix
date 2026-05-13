{
  description = "cabanashmul — dendritic Home Manager starter";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager.url                    = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url                    = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    zshmul.url                    = "github:shmul95/zshmul";
    zshmul.inputs.nixpkgs.follows = "nixpkgs";
    tshmux.url                    = "github:shmul95/tshmux";
    tshmux.inputs.nixpkgs.follows = "nixpkgs";
    shmulvim.url                    = "github:shmul95/shmulvim";
    shmulvim.inputs.nixpkgs.follows = "nixpkgs";
    get-shmul-done.url              = "github:cabanashmul/get-shmul-done?ref=v1.0.2";
    get-shmul-done.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: cabanashmul/shelp repo must be created and pushed to GitHub
    # before `nix flake update` and `nix flake check` will pass here.
    # Steps: create github.com/cabanashmul/shelp, push shelp/ subdirectory
    # from cabanashmul-landing-page repo, then run `nix flake update shelp`.
    shelp.url                    = "github:cabanashmul/shelp";
    shelp.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      imports =
        # Load _options.nix and _builder.nix first (underscore prefix is excluded
        # by import-tree's default filter, so they are listed explicitly).
        [ ./public/_options.nix ./public/_builder.nix ]
        ++ (inputs.import-tree ./public).imports
        ++ (if builtins.pathExists ./private  then (inputs.import-tree ./private).imports  else [])
        ++ (if builtins.pathExists ./profiles then (inputs.import-tree ./profiles).imports else [])
        ++ (if builtins.pathExists ./local.nix then [ ./local.nix ] else []);
    };
}
