{
  inputs,
  nixpkgs,
  ...
}: let
  inherit (builtins) concatLists attrValues mapAttrs elemAt match readDir filter;
  inherit (nixpkgs.lib) hasSuffix nixosSystem;
  inherit (nixpkgs.lib.filesystem) listFilesRecursive;
in rec {
  isNixFile = path: hasSuffix ".nix" path;

  mkSystem = hostname:
    nixosSystem {
      system = "x86_64-linux";
      modules =
        [ ../modules/roles/common.nix ] ++
        builtins.filter isNixFile (listFilesRecursive (../. + "/hosts/${hostname}"));
      specialArgs = {inherit inputs;};
    };

  mapHosts = dir:
    mapAttrs
    (name: _: mkSystem name)
    (readDir dir);

  # https://github.com/balsoft/nixos-config/blob/73cc2c3a8bb62a9c3980a16ae70b2e97af6e1abd/flake.nix#L109-L120
  findModules = dir:
    concatLists (attrValues (mapAttrs
      (name: type:
        if type == "regular"
        then [
          {
            name = elemAt (match "(.*)\\.nix" name) 0;
            value = dir + "/${name}";
          }
        ]
        else if
          (readDir (dir + "/${name}"))
          ? "default.nix"
        then [
          {
            inherit name;
            value = dir + "/${name}";
          }
        ]
        else findModules (dir + "/${name}")) (readDir dir)));
}
