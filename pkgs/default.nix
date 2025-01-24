{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) flakeFromSystem;
  flake = flakeFromSystem pkgs.system;

in
{
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };

  distrobox = pkgs.callPackage ./distrobox { };

  llm-with-plugins = pkgs.callPackage ./llm/llm-with-plugins { };

  lix = pkgs.callPackage ./lix { inherit flake; };
}
// (flake.toPackageAttrs [
  "pixi"
  "f1multiviewer"
  "tsm"
])
