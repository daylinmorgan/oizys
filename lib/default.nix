{
  inputs,
  nixpkgs,
  ...
}: let
  inherit (builtins) concatLists attrValues mapAttrs elemAt match readDir filter listToAttrs baseNameOf readFile;
  inherit (nixpkgs.lib) hasSuffix nixosSystem genAttrs;
  inherit (nixpkgs.lib.filesystem) listFilesRecursive;

  # https://xeiaso.net/blog/nix-flakes-1-2022-02-21/
  supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  forAllSystems = genAttrs supportedSystems;
  nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
in rec {
  shToPkg = path:
    forAllSystems (
      system: let
        name = baseNameOf path;
        pkgs = nixpkgsFor.${system};
      in {
        ${name} = pkgs.writeScriptBin name (readFile path);
      }
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
