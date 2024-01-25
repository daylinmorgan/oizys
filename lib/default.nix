{
  inputs,
  nixpkgs,
  ...
}: let
  inherit (builtins) concatLists attrValues mapAttrs elemAt match readDir filter listToAttrs baseNameOf readFile;
  inherit (nixpkgs.lib) hasSuffix nixosSystem genAttrs;
  inherit (nixpkgs.lib.filesystem) listFilesRecursive;

  supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
in rec {
  forAllSystems = f: genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

  shToPkg = path:
    forAllSystems (
      pkgs: let
        name = baseNameOf path;
      in {${name} = pkgs.writeScriptBin name (readFile path);}
    );

  isNixFile = path: hasSuffix ".nix" path;

  mkSystem = hostname:
    nixosSystem {
      system = "x86_64-linux";
      modules =
        [../modules/roles/common.nix]
        ++ filter isNixFile (listFilesRecursive (../. + "/hosts/${hostname}"));
      specialArgs = {inherit inputs;};
    };

  mapHosts = dir:
    mapAttrs
    (name: _: mkSystem name)
    (readDir dir);

  findModules = modulesPath: listToAttrs (findModulesList modulesPath);
  # https://github.com/balsoft/nixos-config/blob/73cc2c3a8bb62a9c3980a16ae70b2e97af6e1abd/flake.nix#L109-L120
  findModulesList = dir:
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
        else findModulesList (dir + "/${name}")) (readDir dir)));
}
