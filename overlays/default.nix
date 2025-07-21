{ inputs, lib }:
(lib.loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  # inputs.niri.overlays.default # adds main branch niri

  (
    final: prev:

    lib.selfPkgsOverlays final [
      "nimble"
      "nimlangserver"
      # "attic-client"
      # "attic-server"
    ]

    # // lib.pkgsFromNixpkgs final "nixpkgs-unstable" [
    # ]
  )
]
