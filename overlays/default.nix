{ inputs, lib }:
(lib.loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  # inputs.niri.overlays.default # adds main branch niri
]
++ [
  # make this a single oizys overlay?
  (final: _prev: lib.selfPkgOverlays final // lib.pkgsFromNixpkgs final)
]
