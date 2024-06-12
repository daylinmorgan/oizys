{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";

    lix.url = "git+https://git@git.lix.systems/lix-project/lix?ref=refs/tags/2.90-beta.1";
    lix.flake = false;

    lix-module.url = "git+https://git.lix.systems/lix-project/nixos-module";
    lix-module.inputs.lix.follows = "lix";
    # lix-module.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    # see todo.md
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1&rev=4cdddcfe466cb21db81af0ac39e51cc15f574da9";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";

    hyprland-contrib.url = "github:hyprwm/contrib";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    zig2nix.url = "github:Cloudef/zig2nix";
    zig2nix.inputs.nixpkgs.follows = "nixpkgs";
    zls.url = "github:zigtools/zls";
    zls.inputs.nixpkgs.follows = "nixpkgs";

    roc.url = "github:roc-lang/roc";
    roc.inputs.nixpkgs.follows = "nixpkgs";

    tsm.url = "github:daylinmorgan/tsm?dir=nix";
    tsm.inputs.nixpkgs.follows = "nixpkgs";
    hyprman.url = "git+https://git.dayl.in/daylin/hyprman.git";
    hyprman.inputs.nixpkgs.follows = "nixpkgs";
    f1multiviewer.url = "github:daylinmorgan/f1multiviewer-flake";
    pixi.url = "github:daylinmorgan/pixi-flake";
  };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://daylin.cachix.org"
      "https://cache.lix.systems"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };
}
