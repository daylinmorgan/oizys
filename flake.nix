{
  description = "nix begat oizys";

  outputs = inputs: (import ./lib inputs).oizysFlake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.05";
    my-nixpkgs.url = "github:daylinmorgan/nixpkgs/nixos-unstable";

    # lix = {
    #   url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
    #   flake = false;
    # };
    # lix-module = {
    #   url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.lix.follows = "lix";
    # };
    #
    # lix is failing to build only on GHA?
    # keep for when lix breaks :/
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland/?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.systems.follows = "systems";
      inputs.pre-commit-hooks.follows = "";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      # breaks their cache...
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lib-aggregate.follows = "lib-aggregate";
      inputs.nix-eval-jobs.follows = "";
      inputs.flake-compat.follows = "";
    };

    f1multiviewer = {
      url = "github:daylinmorgan/f1multiviewer-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tsm = {
      url = "github:daylinmorgan/tsm?dir=nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nim2nix.follows = "nim2nix";
      };
    };
    hyprman = {
      url = "git+https://git.dayl.in/daylin/hyprman.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nim2nix.follows = "nim2nix";
    };
    utils = {
      url = "git+https://git.dayl.in/daylin/utils.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nim2nix.follows = "nim2nix";
      };
    };
    nim2nix = {
      url = "github:daylinmorgan/nim2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pixi = {
      url = "github:daylinmorgan/pixi-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jj = {
      url = "github:martinvonz/jj/v0.25.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    NixVirt = {
      # master as of 2024.12.12
      url = "github:AshleyYakeley/NixVirt?rev=fe3aaa86d4458e4f84348941297f7ba82e2a9f67";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # included to reduce flake.lock size
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
    };
    lib-aggregate = {
      url = "github:nix-community/lib-aggregate";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
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
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "oizys:DSw3mwVMM/Y+PXSVpkDlU5dLwlORuiJRGPkwr5INSMc="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };
}
