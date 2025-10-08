{ lib, ... }:
final: prev:
let
  inherit (lib.data) lixVersion;
  lixPackageSets = final.lixPackageSets.${lixVersion};
  overrideNix = name: {
    value = prev.${name}.override {
      nix = lixPackageSets.lix;
    };
  };
in
{
  inherit (lixPackageSets)
    nixpkgs-review
    nix-eval-jobs
    nix-index
    nix-fast-build
    colmena
    # nix-direnv I think using programs.nix-direnv already overrides the nix version
    ;
}
// (
  # these are not already included in lixPackageSets
  [
    "nixos-rebuild-ng"
    "comma"
  ]
  |> map (name: {
    inherit name;
    inherit (overrideNix name) value;
  })
  |> lib.listToAttrs

)
