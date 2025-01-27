{ ... }:
let
  inherit (builtins)
    concatLists
    attrValues
    mapAttrs
    elemAt
    match
    readDir
    ;
in
rec {

  handleModule =
    dir: name: type:
    if type == "regular" then
      [
        {
          name = elemAt (match "(.*)\\.nix" name) 0;
          value = dir + "/${name}";
        }
      ]
    else if (readDir (dir + "/${name}")) ? "default.nix" then
      [
        {
          inherit name;
          value = dir + "/${name}";
        }
      ]
    else
      findModulesList (dir + "/${name}");

  findModulesList = dir: (readDir dir) |> mapAttrs (handleModule dir) |> attrValues |> concatLists;
}
