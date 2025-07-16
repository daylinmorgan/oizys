{ inputs, lib }:
let
  inherit (lib) loadOverlays loadNixpkgOverlays;
in
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
  # inputs.niri.overlays.default # adds main branch niri

  (final: prev: rec {
    inherit (loadNixpkgOverlays final) nixpkgs-unstable nixpkgs-master nixpkgs-pr-425784;

    attic-client = inputs.self.packages.${final.system}.attic-client;
    attic-server = inputs.self.packages.${final.system}.attic-server;
    gimp = nixpkgs-master.gimp;
    # TODO: automate this step with an associated PR  number with nixpkgs/pr-tracker?
    gimp = nixpkgs-master.gimp; # 425710
    clisp = nixpkgs-master.clisp; # 425299
  })
]
