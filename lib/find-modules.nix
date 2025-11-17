lib:
let
  inherit (builtins)
    concatLists
    attrValues
    mapAttrs
    readDir
    ;
  inherit (lib) hasSuffix removeSuffix;
  mkModuleAttr = name: value: [ { inherit name value; } ];
in
rec {
  handleModule =
    dir: name: type:
    let
      path = dir + "/${name}";
    in
    if type == "regular" && hasSuffix ".nix" name then
      mkModuleAttr (removeSuffix ".nix" name) path
    else if type == "directory" && (readDir path) ? "default.nix" then
      mkModuleAttr name path
    else if type == "directory" then
      findModulesList path
    else
      [ ];

  findModulesList = dir: dir |> readDir |> mapAttrs (handleModule dir) |> attrValues |> concatLists;
}
