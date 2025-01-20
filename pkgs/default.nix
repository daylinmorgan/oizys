{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) flakeFromSystem;
  flake = flakeFromSystem pkgs.system;
  lix = pkgs.callPackage ./lix { inherit flake; };

  # make attic also use the "no check lix"
  atticPackages = pkg: {
    "${pkg}" = (flake.pkgs "lix-attic").${pkg}.overrideAttrs (oldAttrs: {
      buildInputs = [ pkgs.boost lix ];
    });
  };

in
{
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };

  distrobox = pkgs.callPackage ./distrobox { };

  llm-with-plugins = pkgs.callPackage ./llm/llm-with-plugins { };

  lix = lix;
}
// (atticPackages "attic-client")
// (atticPackages "attic-server")
// (flake.toPackageAttrs [
  "pixi"
  "f1multiviewer"
  "tsm"
])
