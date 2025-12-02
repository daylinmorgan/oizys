{ lib, ... }:
final: prev:
if lib.data.lixModule then
  { }
else
  {
    inherit (final.lixPackageSets.${lib.data.lixVersion})
      nixpkgs-review
      nix-eval-jobs
      nix-index
      nix-fast-build
      colmena
      # nix-direnv I think using programs.nix-direnv already overrides the nix version
      ;
  }
  // {
    comma = prev.comma.override {
      nix = final.lixPackageSets.${lib.data.lixVersion}.lix;
    };
  }
