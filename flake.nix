{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.05";
    my-nixpkgs.url = "github:daylinmorgan/nixpkgs/nixos-unstable";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
    # keep for when lix breaks :/
    # lix-module = {
    #   url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-1.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # https://github.com/ghostty-org/ghostty/issues/2025
    ghostty.url = "git+ssh://git@github.com/ghostty-org/ghostty";
    ghostty.inputs.nixpkgs-stable.follows = "nixpkgs";
    ghostty.inputs.nixpkgs-unstable.follows = "nixpkgs";

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";
    hyprland-contrib.url = "github:hyprwm/contrib";

    f1multiviewer.url = "github:daylinmorgan/f1multiviewer-flake";
    f1multiviewer.inputs.nixpkgs.follows = "nixpkgs";
    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    hyprman.url = "git+https://git.dayl.in/daylin/hyprman.git";
    hyprman.inputs.nixpkgs.follows = "nixpkgs";
    utils.url = "git+https://git.dayl.in/daylin/utils.git";
    utils.inputs.nim2nix.follows = "nim2nix";
    nim2nix.url = "github:daylinmorgan/nim2nix";
    nim2nix.inputs.nixpkgs.follows = "nixpkgs";
    pixi.url = "github:daylinmorgan/pixi-flake";
    pixi.inputs.nixpkgs.follows = "nixpkgs";

    # roc = {
    #   url = "github:roc-lang/roc";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # zig-overlay.url = "github:mitchellh/zig-overlay";
    # zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # zls.url = "github:zigtools/zls";
    # zls.inputs.nixpkgs.follows = "nixpkgs";
    # zls.inputs.zig-overlay.follows = "zig-overlay";
 
  };

  nixConfig = {
    extra-substituters = [
      "https://attic.dayl.in/oizys"
      "https://hyprland.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://daylin.cachix.org"
    ];
    extra-trusted-public-keys = [
      "oizys:DSw3mwVMM/Y+PXSVpkDlU5dLwlORuiJRGPkwr5INSMc="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
    ];
  };
}
