{ lib, ... }:
final: prev:
let
  # issue in stable (2.93.3) with fetchurl while running as sudo
  lixPackageSets = final.lixPackageSets.${lib.data.lixVersion};
in
{
  inherit (lixPackageSets)
    nixpkgs-review
    nix-eval-jobs
    nix-index

    # nix-direnv... I think using programs.nix-direnv already overrides the nix version I think

    # I don't actually use these..
    # nix-fast-build
    # colmena
    ;
}
// (
  [
    "nixos-rebuild-ng"
    "comma"
  ]
  |> map (name: {
    inherit name;
    value = prev.${name}.override {
      nix = lixPackageSets.lix;
    };
  })
  |> prev.lib.listToAttrs

)
