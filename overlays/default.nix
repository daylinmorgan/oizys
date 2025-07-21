{ inputs, lib }:
(lib.loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  # inputs.niri.overlays.default # adds main branch niri

  (final: prev: {
    attic-client = inputs.self.packages.${final.system}.attic-client;
    attic-server = inputs.self.packages.${final.system}.attic-server;
  }
  # // lib.pkgsFromNixpkgs final "nixpkgs-unstable" [
  # ]
  )
]
