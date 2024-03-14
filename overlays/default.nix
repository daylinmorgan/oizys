{inputs, ...}: let
  defaultOverlays =
    # execute and import all overlay files in the current
    # directory with the given args
    builtins.map
    # execute and import the overlay file
    (f: (import (./. + "/${f}") {inherit inputs;}))
    # find all overlay files in the current directory
    (builtins.filter
      (f: f != "default.nix")
      (builtins.attrNames (builtins.readDir ./.)));
in {
  nixpkgs.overlays =
    defaultOverlays
    ++ [
      (
        final: _prev: {
          stable = import inputs.stable {
            system = final.system;
            config.allowUnfree = true;
          };
        }
      )
    ];
}
