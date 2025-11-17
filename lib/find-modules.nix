lib:
let
  inherit (builtins)
    concatLists
    attrValues
    mapAttrs
    readDir
    ;
  inherit (lib) hasSuffix removeSuffix;
  fileToModule = dir: name: [
    {
      name = removeSuffix ".nix" name;
      value = dir + "/${name}";
    }
  ];

  fileToModuleIfNix = dir: name: if hasSuffix ".nix" name then fileToModule dir name else [ ];
  dirToModule = dir: name: [
    {
      inherit name;
      value = dir + "/${name}";
    }
  ];
in
rec {
  handleModule =
    dir: name: type:
    if type == "regular" then
      fileToModuleIfNix dir name
    else if (readDir (dir + "/${name}")) ? "default.nix" then
      dirToModule dir name
    else
      findModulesList (dir + "/${name}");

  findModulesList =
    dir: lib.traceValSeq (dir |> readDir |> mapAttrs (handleModule dir) |> attrValues |> concatLists);
}
