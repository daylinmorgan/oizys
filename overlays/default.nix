{ inputs, lib }:
let
  inherit (lib) loadOverlays pkgsFromMaster;
in
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  # inputs.niri.overlays.default # adds main branch niri

  (
    final: prev:
    {
      attic-client = inputs.self.packages.${final.system}.attic-client;
      attic-server = inputs.self.packages.${final.system}.attic-server;
    }
    // pkgsFromMaster final [
      "gimp" # 425710
      "clisp" # 425299
      "pcmanfm" # 425784
    ]
  )
]
