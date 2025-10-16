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
  distrobox = pkgs.callPackage ./distrobox { };
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };
  lix = flake.pkg "lix-module";
  inherit (flake.pkgs "lix-module") nix-eval-jobs;
}
// (flake.toPackageAttrs [
  "multiviewer"
  "tsm"
  "llm-nix"
  "niriman"
  "daylin-website"
])
