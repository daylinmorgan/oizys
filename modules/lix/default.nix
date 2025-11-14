{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.data) lixVersion;
in
{
  nixpkgs.overlays = [
    (import ./overlay.nix { inherit lib; })
  ];
  nix.package = pkgs.lixPackageSets.${lixVersion}.lix;
}
