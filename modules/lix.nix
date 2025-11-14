{
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib.data) lixVersion lixModule;
in
(
  if lixModule then
    { imports = [ (flake.module "lix-module") ]; }
  else
    { nix.package = pkgs.lixPackageSets.${lixVersion}.lix; }
)
