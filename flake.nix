{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };

    # hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1&rev=300228b503b36e5977b0d58713c5b4cf1f07b8a9";
    hyprland-contrib.url = "github:hyprwm/contrib";

    # zls build failure?
    zig2nix = {
      url = "github:Cloudef/zig2nix/9ec43c3e2cfd195bc7cbe3924037788e72a958e3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls = {
      url = "github:zigtools/zls/adf3b839b19df88c09877526007d8347ec982abb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    roc = {
      url = "github:roc-lang/roc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pixi.url = "github:daylinmorgan/pixi-flake";

    f1multiviewer.url = "github:daylinmorgan/f1multiviewer-flake";
    tsm = {
      url = "github:daylinmorgan/tsm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprman = {
      url = "git+https://git.dayl.in/daylin/hyprman.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
