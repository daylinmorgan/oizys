{ inputs, lib }:
let
  inherit (lib) loadOverlays loadNixpkgOverlays;
in
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage

  (final: prev: rec {
    inherit (loadNixpkgOverlays final) nixpkgs-unstable;

    attic-client = inputs.self.packages.${final.system}.attic-client;
    attic-server = inputs.self.packages.${final.system}.attic-server;
    hplip = nixpkgs-unstable.hplip;
  })
]
