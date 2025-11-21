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
    inherit (flake.pkgs "lix-module") nix-eval-jobs;
    lix = flake.pkg "lix-module";
  }
else
  (
    ''
      lix
      nix-eval-jobs
    ''
    |> lib.listifyMapToNamedAttrs (name: pkgs.lixPackageSets.${lixVersion}.${name})
  )
