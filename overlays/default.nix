{ inputs, ... }:
let
  inherit (builtins)
    map
    filter
    attrNames
    readDir
    elem
    ;
  # execute and import all overlay files in the current
  # directory with the given args
  # overlays =
  #    map
  #     (f: (import (./. + "/${f}") { inherit inputs; }))
  #     (filter (f: f != "default.nix") (attrNames (readDir ./.)));
  ignore = ["nimlangserver"];
  overlays =
    readDir ./.
    |> attrNames
    |> filter (f: f != "default.nix" || elem f ignore)
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
