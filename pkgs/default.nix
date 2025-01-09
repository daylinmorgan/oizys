{ pkgs, ... }:
let
  inherit (pkgs) python3Packages;
in
{
  # nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };

  distrobox = pkgs.callPackage ./distrobox { };

  llm = python3Packages.callPackage ./llm { };
  llm-claude-3 = python3Packages.callPackage ./llm-plugins/llm-claude-3 { };
}
