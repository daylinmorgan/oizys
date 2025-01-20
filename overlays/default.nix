{ inputs, loadOverlays }:
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage

  (final: prev: {

    # make sure attic is using this lix
    nix = inputs.self.packages.${final.system}.lix;


    stable = import inputs.stable {
      system = final.system;
      config.allowUnfree = true;
    };

    # nixd + lix = problem, or am I just pulling in nix2.24 now?
    nixt = prev.nixt.override {
      nix = final.nixVersions.nix_2_24;
    };

    nixd = prev.nixd.override {
      nix = final.nixVersions.nix_2_24;
    };
  })
]
