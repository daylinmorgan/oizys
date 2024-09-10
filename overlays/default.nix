{ inputs, loadOverlays }:
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  (final: _prev: {
    stable = import inputs.stable {
      system = final.system;
      config.allowUnfree = true;
    };
  })
]
