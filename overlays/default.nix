{ inputs, loadOverlays }:

let
  inherit (inputs.nixpkgs.lib) listToAttrs;

  allNixpkgs = [
    "nixpkgs-stable"
    "nixpkgs-unstable"
    "mynixpkgs"
  ];
  nixpkgsOverlays =
    final:
    allNixpkgs
    |> map (name: {
      inherit name;
      value = import inputs."${name}" {
        inherit (final) system config;
      };
    })
    |> listToAttrs;

in
(loadOverlays inputs ./.)
++ [
  inputs.nim2nix.overlays.default # adds buildNimPackage
]
++ [
  (final: prev: rec {
    inherit (nixpkgsOverlays final) nixpkgs-unstable nixpkgs-stable mynixpkgs;

    attic-client = inputs.self.packages.${final.system}.attic-client;
    attic-server = inputs.self.packages.${final.system}.attic-server;
    hplip = nixpkgs-unstable.hplip;
  })
]
