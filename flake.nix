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

    get-shmul-done.url              = "github:cabanashmul/get-shmul-done";
    get-shmul-done.inputs.nixpkgs.follows = "nixpkgs";

    hermes-agent.url                    = "github:NousResearch/hermes-agent";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";

    hermes-shmulsidian.url                    = "github:cabanashmul/hermes-shmulsidian";
    hermes-shmulsidian.inputs.nixpkgs.follows = "nixpkgs";

    memtide-vault.url                    = "github:EIP-memtide/memtide-vault";
    memtide-vault.inputs.nixpkgs.follows = "nixpkgs";

    # Points at the vault repo (github:shmul95/shmulsidian), which re-exports
    # lib.mkOverlay and homeManagerModules from shmulsidian-template.
    # New operators: fork the template, add YOUR vault as shmulsidian input.
    shmulsidian.url                  = "git+ssh://git@github.com/shmul95/shmulsidian";
    shmulsidian.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: cabanashmul/shelp repo must be created and pushed to GitHub
    # before `nix flake update` and `nix flake check` will pass here.
    # Steps: create github.com/cabanashmul/shelp, push shelp/ subdirectory
    # from cabanashmul-landing-page repo, then run `nix flake update shelp`.
    shelp.url                    = "github:cabanashmul/shelp";
    shelp.inputs.nixpkgs.follows = "nixpkgs";

    # Claude skills for bootstrapping multi-repo projects.
    # Data-only flake (just SKILL.md files); no nixpkgs follows needed.
    decompose-project.url = "github:cabanashmul/decompose-project";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      imports =
        # Load _options.nix and _builder.nix first (underscore prefix is excluded
        # by import-tree's default filter, so they are listed explicitly).
        [ ./public/_options.nix ./nixos/_options.nix ./public/_builder.nix ./nixos/_builder.nix ]
        ++ (inputs.import-tree ./public).imports
        ++ (if builtins.pathExists ./nixos   then (inputs.import-tree ./nixos).imports   else [])
        ++ (if builtins.pathExists ./private  then (inputs.import-tree ./private).imports  else [])
        ++ (if builtins.pathExists ./profiles then (inputs.import-tree ./profiles).imports else [])
        ++ (if builtins.pathExists ./local.nix then [ ./local.nix ] else []);
    };
}
