{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.05";
    my-nixpkgs.url = "github:daylinmorgan/nixpkgs/nixos-unstable";

    lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    lix-module.inputs.nixpkgs.follows = "nixpkgs";
    lix-module.inputs.flake-utils.follows = "flake-utils";
    lix-module.inputs.lix.follows = "lix";
    lix.url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
    lix.flake = false;
    # keep for when lix breaks :/
    # lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-index-database.url = "github:nix-community/nix-index-database";
    sops-nix.url = "github:Mic92/sops-nix";
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";
    hyprland-contrib.url = "github:hyprwm/contrib";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    llm-nix.url = "github:daylinmorgan/llm-nix";
    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    hyprman.url = "git+https://git.dayl.in/daylin/hyprman.git";
    nim2nix.url = "github:daylinmorgan/nim2nix";
    utils.url = "git+https://git.dayl.in/daylin/utils.git";

    f1multiviewer.url = "github:daylinmorgan/f1multiviewer-flake";
    pixi.url = "github:daylinmorgan/pixi-flake";
    roc.url = "github:roc-lang/roc/0.0.0-alpha2-rolling";

    # master as of 2024.12.12
    NixVirt.url = "github:AshleyYakeley/NixVirt?rev=9063243af5e6674359a0ff7cec57f02eeacf0cea";

    # zig-overlay.url = "github:mitchellh/zig-overlay";
    # zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # zls.url = "github:zigtools/zls";
    # zls.inputs.nixpkgs.follows = "nixpkgs";
    # zls.inputs.zig-overlay.follows = "zig-overlay";

    # Follows

    ## nixpkgs
    f1multiviewer.inputs.nixpkgs.follows = "nixpkgs";
    # hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprman.inputs.nixpkgs.follows = "nixpkgs";
    llm-nix.inputs.nixpkgs.follows = "nixpkgs";
    nim2nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";
    pixi.inputs.nixpkgs.follows = "nixpkgs";
    roc.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    ## nim2nix
    hyprman.inputs.nim2nix.follows = "nim2nix";
    tsm.inputs.nim2nix.follows = "nim2nix";
    utils.inputs.nim2nix.follows = "nim2nix";

    # further flake.lock minimization shenanigans
    # hyprland-qt-support.url = "github:hyprwm/hyprland-qt-support";
    # hyprland-qt-support.inputs.hyprlang.follows = "hyprland/hyprlang";
    # hyprland-qt-support.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    # hyprland-qt-support.inputs.systems.follows = "hyprland/systems";
    # hyprland-qtutils.url = "github:hyprwm/hyprland-qtutils";
    # hyprland-qtutils.inputs.hyprland-qt-support.follows = "hyprland-qt-support";
    # hyprland-qtutils.inputs.hyprlang.follows = "hyprland/hyprlang";
    # hyprland-qtutils.inputs.hyprutils.follows = "hyprland/hyprutils";
    # hyprland-qtutils.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    # hyprland-qtutils.inputs.systems.follows = "hyprland/systems";
    # hyprland.inputs.hyprland-qtutils.follows = "hyprland-qtutils";

    systems.url = "github:nix-systems/x86_64-linux";
    # hyprland.inputs.systems.follows = "systems";
    flake-utils.inputs.systems.follows = "systems";

    flake-utils.url = "github:numtide/flake-utils";
    lib-aggregate.inputs.flake-utils.follows = "flake-utils";
    roc.inputs.flake-utils.follows = "flake-utils";

    lib-aggregate.url = "github:nix-community/lib-aggregate";
    nixpkgs-wayland.inputs.lib-aggregate.follows = "lib-aggregate";

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    lib-aggregate.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    roc.inputs.rust-overlay.follows = "rust-overlay";

    ## nil inputs, I don't want *ALL* your flake inputs...
    # hyprland.inputs.pre-commit-hooks.follows = "";
    nixos-wsl.inputs.flake-compat.follows = "";
    nixpkgs-wayland.inputs.flake-compat.follows = "";

  };

  nixConfig = {
    extra-substituters = [
      "https://nix-cache.dayl.in"
    ];
    extra-trusted-public-keys = [
      "nix-cache.dayl.in-1:lj22Sov7m1snupBz/43O1fxyEfy/S7cxBpweD7iREcs"
    ];
  };
}
