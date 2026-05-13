{
  system,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) flakeFromSystem;
  flake = flakeFromSystem system;
  nim-nnl-update-script = pkgs.callPackage ./nim/nim-nnl-update-script { };
in
{
  oizys = pkgs.callPackage ../pkgs/oizys {
    inherit (lib.data.substituters) substituters trusted-public-keys;
  };

  inherit nim-nnl-update-script;
  distrobox = pkgs.callPackage ./distrobox { };
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { inherit nim-nnl-update-script; };
  procs = pkgs.callPackage ./nim/procs { inherit nim-nnl-update-script; };
  nimble = pkgs.callPackage ./nim/nimble { };
  nim-atlas = pkgs.callPackage ./nim/atlas { inherit nim-nnl-update-script; };
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins { };
  firefox = pkgs.callPackage ./firefox { };
  inherit (pkgs) difftastic;
}
// (import ./lix.nix { inherit flake lib pkgs; })
// (flake.toPackageAttrs [
  # "multiviewer"
  "tsm"
  "llm-nix"
  "niriman"
  "daylin-website"
  "celler"
])
