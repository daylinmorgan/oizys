{
  system,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) flakeFromSystem;
  flake = flakeFromSystem system;
in
{
  distrobox = pkgs.callPackage ./distrobox { };
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };
  nim-atlas = pkgs.callPackage ./nim/atlas { };
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins { };
}
// (import ./lix.nix { inherit flake lib pkgs; })
// (flake.toPackageAttrs [
  "multiviewer"
  "tsm"
  "llm-nix"
  "niriman"
  "daylin-website"
])
