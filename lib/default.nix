{
  inputs,
  self,
}: let
  inherit (inputs) nixpkgs;
  inherit (builtins) concatLists attrValues mapAttrs elemAt match readDir filter listToAttrs;
  inherit (nixpkgs.lib) hasSuffix nixosSystem genAttrs;
  inherit (nixpkgs.lib.filesystem) listFilesRecursive;

  lib = nixpkgs.lib.extend (import ./extended.nix);
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = ["x86_64-linux"];
in rec {
  forAllSystems = f: genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

  isNixFile = path: hasSuffix ".nix" path;
  buildOizys = _:
    forAllSystems (
      pkgs: let
        pkg = pkgs.callPackage ../oizys {};
      in {
        oizys = pkg;
        default = pkg;
      }
    );

  mkSystem = hostname:
    nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          ../modules/common.nix
          ../overlays
        ]
        ++ filter
        isNixFile
        (listFilesRecursive (../. + "/hosts/${hostname}"));

      specialArgs = {inherit inputs lib self;};
    };
  mapHosts = dir: mapAttrs (name: _: mkSystem name) (readDir dir);

  findModules = _: listToAttrs (findModulesList ../modules);
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

  oizysFlake = _: {
    nixosModules = findModules {};
    nixosConfigurations = mapHosts ../hosts;
    packages = buildOizys {};
    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
