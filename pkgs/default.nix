{
  system,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) flakeFromSystem;
  flake = flakeFromSystem system;
  nim-nnl-update-script = pkgs.callPackage ./nim/nim-nnl-update-script { inherit flake;};
  callNimPackage = p: pkgs.callPackage p { inherit nim-nnl-update-script; };
in
{
  oizys = pkgs.callPackage ../pkgs/oizys {
    inherit (lib.data.substituters) substituters trusted-public-keys;
  };

  nimlangserver = callNimPackage ./nim/nimlangserver;
  procs = callNimPackage ./nim/procs;
  nimble = pkgs.callPackage ./nim/nimble { };
  nim-atlas = callNimPackage ./nim/atlas;
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
