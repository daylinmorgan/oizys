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
  inherit (flake.pkgs "lix-module") nix-eval-jobs;
  lix = flake.pkg "lix-module";

  distrobox = pkgs.callPackage ./distrobox { };
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };
  # nim-atlas = pkgs.callPackage ./nim/atlas {};
  nim-atlas = (flake.pkgs "nim2nix").atlas;
}
// (flake.toPackageAttrs [
  "multiviewer"
  "tsm"
  "llm-nix"
  "niriman"
  "daylin-website"
])
