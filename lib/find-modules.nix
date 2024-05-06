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
  # https://github.com/balsoft/nixos-config/blob/73cc2c3a8bb62a9c3980a16ae70b2e97af6e1abd/flake.nix#L109-L120
  findModulesList =
    dir:
    concatLists (
      attrValues (
        mapAttrs (
          name: type:
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
            findModulesList (dir + "/${name}")
        ) (readDir dir)
      )
    );
}
