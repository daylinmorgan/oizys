{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = rec {
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    my-nixpkgs.url = "github:daylinmorgan/nixpkgs/nixos-unstable";
    nixpkgs = nixpkgs-nixos-unstable;

    # switch to lix stable from nixpkgs ... see also overlays/lix
    # lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    # lix-module.inputs.nixpkgs.follows = "nixpkgs";
    # lix-module.inputs.flake-utils.follows = "flake-utils";
    # lix-module.inputs.lix.follows = "lix";
    # lix.url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
    # lix.flake = false;
    # keep for when lix breaks :/
    # lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-index-database.url = "github:nix-community/nix-index-database";
    sops-nix.url = "github:Mic92/sops-nix";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland/8dcad9dcb5ce4eb28e2719ab025224308b318e79";

    llm-nix.url = "github:daylinmorgan/llm-nix";
    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    nim2nix.url = "github:daylinmorgan/nim2nix";
    niriman.url = "git+https://git.dayl.in/daylin/niriman.git";
    utils.url = "git+https://git.dayl.in/daylin/utils.git";

    multiviewer.url = "github:daylinmorgan/multiviewer-flake";
    roc.url = "github:roc-lang/roc/0.0.0-alpha2-rolling";

    niri.url = "github:YaLTeR/niri";

    NixVirt.url = "github:AshleyYakeley/NixVirt/v0.6.0";

    daylin-website.url = "https://git.dayl.in/daylin/dayl.in/archive/main.tar.gz";

    # zig-overlay.url = "github:mitchellh/zig-overlay";
    # zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # zls.url = "github:zigtools/zls";
    # zls.inputs.nixpkgs.follows = "nixpkgs";
    # zls.inputs.zig-overlay.follows = "zig-overlay";

    pinix.url = "github:remi-dupre/pinix";
    pinix.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane"; # todo: use tag?

    # Follows

    ## nixpkgs
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
    roc.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    ## nim2nix
    niriman.inputs.nim2nix.follows = "nim2nix";
    tsm.inputs.nim2nix.follows = "nim2nix";
    utils.inputs.nim2nix.follows = "nim2nix";

    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils.inputs.systems.follows = "systems";
    daylin-website.inputs.bun2nix.inputs.systems.follows = "systems";

    flake-utils.url = "github:numtide/flake-utils";
    lib-aggregate.inputs.flake-utils.follows = "flake-utils";
    roc.inputs.flake-utils.follows = "flake-utils";

    lib-aggregate.url = "github:nix-community/lib-aggregate";
    nixpkgs-wayland.inputs.lib-aggregate.follows = "lib-aggregate";

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    lib-aggregate.inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    roc.inputs.rust-overlay.follows = "rust-overlay";
    niri.inputs.rust-overlay.follows = "rust-overlay";

    flake-parts.url = "github:hercules-ci/flake-parts";

    ## nil inputs, I don't want *ALL* your flake inputs...
    nixos-wsl.inputs.flake-compat.follows = "";
    nixpkgs-wayland.inputs.flake-compat.follows = "";
    daylin-website.inputs.bun2nix.inputs.treefmt-nix.follows = "";

    # lix-attic.url = "git+https://git.lix.systems/nrabulinski/attic.git";
    # # lix-attic.url = "git+https://git.dayl.in/daylin/attic.git";
    # lix-attic.inputs.lix.follows = "lix-module/lix";
    # lix-attic.inputs.lix-module.follows = "lix-module";
    # lix-attic.inputs.nixpkgs.follows = "nixpkgs";
    # lix-attic.inputs.flake-parts.follows = "flake-parts";
    #
    # lix-attic.inputs.nixpkgs-stable.follows = "";
    # lix-attic.inputs.flake-compat.follows = "";
    # lix-attic.inputs.nix-github-actions.follows = "";
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-cache.dayl.in/oizys"
    ];
    extra-trusted-public-keys = [
      "nix-cache.dayl.in-1:lj22Sov7m1snupBz/43O1fxyEfy/S7cxBpweD7iREcs"
    ];
  };
}
