inputs@{ nixpkgs, self, ... }:
let
  lib = nixpkgs.lib.extend (import ./extended.nix);

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib) genAttrs;

  inherit (import ./find-modules.nix { inherit lib; }) findModulesList;
  inherit (import ./generators.nix { inherit lib self inputs; }) mkIso mkSystem;
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = [ "x86_64-linux" ];
  forAllSystems = f: genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));

  oizysFlake = {
    nixosModules = listToAttrs (findModulesList ../modules);
    nixosConfigurations = mapAttrs (name: _: mkSystem name) (readDir ../hosts);
    packages = forAllSystems (pkgs: rec {
      iso = mkIso.config.system.build.isoImage;
      oizys-go = pkgs.callPackage ../pkgs/oizys { };
      default = oizys-go;
    });
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          git
          deadnix
        ];
      };
    });
    checks = forAllSystems (
      pkgs:
      import ./checks.nix {
        inherit inputs;
        system = pkgs.system;
      }
    );
    formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
  };
in
{
  inherit oizysFlake;
}
