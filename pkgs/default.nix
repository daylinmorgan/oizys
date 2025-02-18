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

  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };

  lix = (flake.pkg "lix-module");

  nix-eval-jobs = pkgs.nix-eval-jobs;

  roc = (flake.pkgs "roc").cli;
  roc-lang-server = (flake.pkgs "roc").lang-server;

  # attic-client = (flake.pkgs "lix-attic").attic-client;
  # attic-server = (flake.pkgs "lix-attic").attic-server;
}
// (flake.toPackageAttrs [
  "pixi"
  "f1multiviewer"
  "tsm"
])
