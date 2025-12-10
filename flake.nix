{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = rec {
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    # nixpkgs-master.url = "github:nixos/nixpkgs/master";
    # my-nixpkgs.url = "github:daylinmorgan/nixpkgs/nixos-unstable";
    nixpkgs = nixpkgs-nixos-unstable;

    # to switch to lix stable from nixpkgs ... see also overlays/lix
    lix.url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
    lix.flake = false;
    lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    lix-module.inputs.nixpkgs.follows = "nixpkgs";
    lix-module.inputs.flake-utils.follows = "flake-utils";
    lix-module.inputs.lix.follows = "lix";

    llm-nix.url = "github:daylinmorgan/llm-nix";
    llm-nix.inputs.nixpkgs.follows = "nixpkgs";

    niri.url = "github:YaLTeR/niri";
    niri.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    NixVirt.url = "github:AshleyYakeley/NixVirt/v0.6.0";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    daylin-website.url = "https://git.dayl.in/daylin/dayl.in/archive/main.tar.gz";
    daylin-website.inputs.nixpkgs.follows = "nixpkgs";
    daylin-website.inputs.bun2nix.follows = "bun2nix";

    multiviewer.url = "github:daylinmorgan/multiviewer-flake";
    multiviewer.inputs.nixpkgs.follows = "nixpkgs";

    nim2nix.url = "github:daylinmorgan/nim2nix";
    nim2nix.inputs.nixpkgs.follows = "nixpkgs";

    niriman.url = "git+https://git.dayl.in/daylin/niriman.git";
    niriman.inputs.nixpkgs.follows = "nixpkgs";
    niriman.inputs.nim2nix.follows = "nim2nix";

    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    tsm.inputs.nim2nix.follows = "nim2nix";

    utils.url = "git+https://git.dayl.in/daylin/utils.git";
    utils.inputs.nixpkgs.follows = "nixpkgs";
    utils.inputs.nim2nix.follows = "nim2nix";

    # zig-overlay.url = "github:mitchellh/zig-overlay";
    # zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # zls.url = "github:zigtools/zls";
    # zls.inputs.nixpkgs.follows = "nixpkgs";
    # zls.inputs.zig-overlay.follows = "zig-overlay";

    # indirect deps
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    lib-aggregate.url = "github:nix-community/lib-aggregate";
    lib-aggregate.inputs.flake-utils.follows = "flake-utils";
    lib-aggregate.inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    niri.inputs.rust-overlay.follows = "rust-overlay";
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/x86_64-linux";

    bun2nix.url = "github:nix-community/bun2nix";
    bun2nix.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      flake-parts.follows = "flake-parts";
      treefmt-nix.follows = "treefmt-nix";
    };
    ## nil inputs, I don't want *ALL* your flake inputs...
    nixos-wsl.inputs.flake-compat.follows = "";
  };
}
