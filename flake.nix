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
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module.inputs.lix.follows = "lix";
    # keep for when lix breaks :/
    # lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-index-database.url = "github:nix-community/nix-index-database";
    sops-nix.url = "github:Mic92/sops-nix";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";
    hyprland-contrib.url = "github:hyprwm/contrib";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    f1multiviewer.url = "github:daylinmorgan/f1multiviewer-flake";
    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    hyprman.url = "git+https://git.dayl.in/daylin/hyprman.git";
    nim2nix.url = "github:daylinmorgan/nim2nix";
    utils.url = "git+https://git.dayl.in/daylin/utils.git";
    pixi.url = "github:daylinmorgan/pixi-flake";
    jj.url = "github:martinvonz/jj/v0.25.0";

    # master as of 2024.12.12
    NixVirt.url = "github:AshleyYakeley/NixVirt?rev=9063243af5e6674359a0ff7cec57f02eeacf0cea";

    # Follows

    ## nixpkgs
    f1multiviewer.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprman.inputs.nixpkgs.follows = "nixpkgs";
    jj.inputs.nixpkgs.follows = "nixpkgs";
    nim2nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";
    pixi.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    ## nim2nix
    hyprman.inputs.nim2nix.follows = "nim2nix";
    tsm.inputs.nim2nix.follows = "nim2nix";
    utils.inputs.nim2nix.follows = "nim2nix";

    # lix-attic = {
    #   url = "git+https://git.lix.systems/nrabulinski/attic.git";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.lix-module.follows = "lix-module";
    #   # make lix-module source of truth
    #   inputs.lix.follows = "lix-module/lix";
    #   inputs.nix-github-actions.follows = "";
    # };

    # roc = {
    #   url = "github:roc-lang/roc";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # zig-overlay.url = "github:mitchellh/zig-overlay";
    # zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # zls.url = "github:zigtools/zls";
    # zls.inputs.nixpkgs.follows = "nixpkgs";
    # zls.inputs.zig-overlay.follows = "zig-overlay";

    # further flake.lock minimization shenanigans
    hyprland-qt-support.url = "github:hyprwm/hyprland-qt-support";
    hyprland-qt-support.inputs.hyprlang.follows = "hyprland/hyprlang";
    hyprland-qt-support.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprland-qt-support.inputs.systems.follows = "hyprland/systems";
    hyprland.inputs.hyprland-qtutils.inputs.hyprland-qt-support.follows = "hyprland-qt-support";

    systems.url = "github:nix-systems/x86_64-linux";
    hyprland.inputs.systems.follows = "systems";
    flake-utils.inputs.systems.follows = "systems";

    flake-utils.url = "github:numtide/flake-utils";
    jj.inputs.flake-utils.follows = "flake-utils";
    lib-aggregate.inputs.flake-utils.follows = "flake-utils";

    lib-aggregate.url = "github:nix-community/lib-aggregate";
    nixpkgs-wayland.inputs.lib-aggregate.follows = "lib-aggregate";

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    lib-aggregate.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    ## nil inputs, I don't *ALL* your flake inputs...
    hyprland.inputs.pre-commit-hooks.follows = "";
    nixos-wsl.inputs.flake-compat.follows = "";
    nixpkgs-wayland.inputs.flake-compat.follows = "";
    nixpkgs-wayland.inputs.nix-eval-jobs.follows = "";

  };

  nixConfig = {
    extra-substituters = [
      "https://attic.dayl.in/oizys"
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "oizys:DSw3mwVMM/Y+PXSVpkDlU5dLwlORuiJRGPkwr5INSMc="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };
}
