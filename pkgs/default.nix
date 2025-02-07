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
  llm-with-plugins = pkgs.callPackage ./llm/llm-with-plugins { };

  # added for access to https://github.com/rclone/rclone/issues/8351
  # can remove when rclone v1.70 hits nixpkgs
  rclone = pkgs.callPackage ./rclone {};

  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };

  lix = (flake.pkg "lix-module");
  roc = (flake.pkgs "roc").cli;
  roc-lang-server = (flake.pkgs "roc").lang-server;
}
// (flake.toPackageAttrs [
  "pixi"
  "f1multiviewer"
  "tsm"
])
