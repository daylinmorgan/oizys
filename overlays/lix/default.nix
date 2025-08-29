inputs: final: prev: {

  nixos-rebuild-ng = prev.nixos-rebuild-ng.override {
    nix = final.lixPackageSets.stable.lix;
  };

  comma = prev.comma.override {
    nix = final.lixPackageSets.stable.lix;
  };

  inherit (final.lixPackageSets.stable)
    nixpkgs-review
    nix-eval-jobs
    nix-index

    # nix-direnv... I think using programs.nix-direnv already overrides the nix version I think

    # I don't actually use these..
    # nix-fast-build
    # colmena
    ;
}
