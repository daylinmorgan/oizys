{ inputs, loadOverlays }:
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  (final: prev: {
    stable = import inputs.stable {
      system = final.system;
      config.allowUnfree = true;
    };

    # nixd + lix = problem, or am I just pulling in nix2.24 now?
    nixt = prev.nixt.override {
      nix = final.nixVersions.nix_2_24;
    };

    nixd = prev.nixt.override {
      nix = final.nixVersions.nix_2_24;
    };
  })
]
