{
  pkgs,
  flake,
  lib,
  ...
}:
let
  inherit (lib.data) lixVersion lixModule;
in
if lixModule then
  {
    inherit (flake.pkgs "lix") nix-eval-jobs;
    lix = flake.pkg "lix";
    nix-update = pkgs.nix-update.override { nix = flake.pkg "lix"; };
  }
else
  (
    ''
      lix
      nix-eval-jobs
      nix-update
    ''
    |> lib.listifyMapToNamedAttrs (name: pkgs.lixPackageSets.${lixVersion}.${name})
  )
