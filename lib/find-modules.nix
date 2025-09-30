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
  fileToModule = dir: name: [
    {
      name = elemAt (match "(.*)\\.nix" name) 0;
      value = dir + "/${name}";
    }
  ];
  dirToModule = dir: name: [
    {
      inherit name;
      value = dir + "/${name}";
    }
  ];

  handleModule =
    dir: name: type:
    if type == "regular" then
      fileToModule dir name
    else if (readDir (dir + "/${name}")) ? "default.nix" then
      dirToModule dir name
    else
      findModulesList (dir + "/${name}");

  findModulesList = dir: dir |> readDir |> mapAttrs (handleModule dir) |> attrValues |> concatLists;
}
