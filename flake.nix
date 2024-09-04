{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-index-database.url = "github:nix-community/nix-index-database";

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";
    hyprland-contrib.url = "github:hyprwm/contrib";
    roc.url = "github:roc-lang/roc";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";

    nim2nix.url = "github:daylinmorgan/nim2nix";
    pixi.url = "github:daylinmorgan/pixi-flake";
    f1multiviewer.url = "github:daylinmorgan/f1multiviewer-flake";
    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    hyprman.url = "git+https://git.dayl.in/daylin/hyprman.git";
    utils.url = "git+https://git.dayl.in/daylin/utils.git";

    nim2nix.inputs.nixpkgs.follows = "nixpkgs";
    hyprman.inputs.nixpkgs.follows = "nixpkgs";
    f1multiviewer.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    pixi.inputs.nixpkgs.follows = "nixpkgs";
    roc.inputs.nixpkgs.follows = "nixpkgs";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    zls.inputs.nixpkgs.follows = "nixpkgs";
    zls.inputs.zig-overlay.follows = "zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://daylin.cachix.org"
      # "https://cache.lix.systems"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
      # "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };
}
