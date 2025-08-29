inputs: final: prev:
let
lixPackageSets = final.lixPackageSets.stable;
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
  [ "nixos-rebuild-ng" "comma"]
  |> map (name: {
    inherit name;
    value = prev.${name}.override {
      nix = lixPackageSets.lix;
    };
  })
  |> prev.lib.listToAttrs

)
