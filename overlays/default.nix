{ inputs, ... }:
let
  inherit (builtins)
    map
    filter
    attrNames
    readDir
    ;
  # execute and import all overlay files in the current
  # directory with the given args
  # overlays =
  #    map
  #     (f: (import (./. + "/${f}") { inherit inputs; }))
  #     (filter (f: f != "default.nix") (attrNames (readDir ./.)));
  overlays =
    readDir ./.
    |> attrNames
    |> filter (f: f != "default.nix")
    |> map (f: import (./. + "/${f}") { inherit inputs; });
in
{
  nixpkgs.overlays = overlays ++ [
    (final: _prev: {
      stable = import inputs.stable {
        system = final.system;
        config.allowUnfree = true;
      };
    })
  ];
}
