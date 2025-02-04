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

  lix = (flake.pkg "lix-module");

  roc = (flake.pkgs "roc").cli;
  roc-lang-server = (flake.pkgs "roc").lang-server;
}
// (flake.toPackageAttrs [
  "pixi"
  "f1multiviewer"
  "tsm"
])
