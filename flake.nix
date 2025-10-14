{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = rec {
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
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

    crane.url = "github:ipetkov/crane/v0.21.1";
    llm-nix.url = "github:daylinmorgan/llm-nix";
    multiviewer.url = "github:daylinmorgan/multiviewer-flake";
    niri.url = "github:YaLTeR/niri";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    NixVirt.url = "github:AshleyYakeley/NixVirt/v0.6.0";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    daylin-website.url = "https://git.dayl.in/daylin/dayl.in/archive/main.tar.gz";
    nim2nix.url = "github:daylinmorgan/nim2nix";
    niriman.url = "git+https://git.dayl.in/daylin/niriman.git";
    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    utils.url = "git+https://git.dayl.in/daylin/utils.git";

    # zig-overlay.url = "github:mitchellh/zig-overlay";
    # zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # zls.url = "github:zigtools/zls";
    # zls.inputs.nixpkgs.follows = "nixpkgs";
    # zls.inputs.zig-overlay.follows = "zig-overlay";

    # all the follows
    daylin-website.inputs.nixpkgs.follows = "nixpkgs";
    multiviewer.inputs.nixpkgs.follows = "nixpkgs";
    llm-nix.inputs.nixpkgs.follows = "nixpkgs";
    nim2nix.inputs.nixpkgs.follows = "nixpkgs";
    niriman.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    niri.inputs.nixpkgs.follows = "nixpkgs";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    niriman.inputs.nim2nix.follows = "nim2nix";
    tsm.inputs.nim2nix.follows = "nim2nix";
    utils.inputs.nim2nix.follows = "nim2nix";

    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils.inputs.systems.follows = "systems";
    daylin-website.inputs.bun2nix.inputs.systems.follows = "systems";

    flake-utils.url = "github:numtide/flake-utils";
    lib-aggregate.inputs.flake-utils.follows = "flake-utils";

    lib-aggregate.url = "github:nix-community/lib-aggregate";
    nixpkgs-wayland.inputs.lib-aggregate.follows = "lib-aggregate";

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    lib-aggregate.inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    niri.inputs.rust-overlay.follows = "rust-overlay";

    flake-parts.url = "github:hercules-ci/flake-parts";

    ## nil inputs, I don't want *ALL* your flake inputs...
    nixos-wsl.inputs.flake-compat.follows = "";
    nixpkgs-wayland.inputs.flake-compat.follows = "";
    daylin-website.inputs.bun2nix.inputs.treefmt-nix.follows = "";
  };
}
