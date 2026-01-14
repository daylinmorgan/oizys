inputs@{
  nixpkgs,
  treefmt-nix,
  self,
  ...
}:
let
  lib = (nixpkgs.lib.extend (import ./extended.nix inputs));

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib) genAttrs findModulesList;
  inherit (import ./generators.nix { inherit lib self inputs; }) mkIso mkSystem;

  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = [ "x86_64-linux" ];
  pkgsForSystem =
    system:
    (import nixpkgs {
      inherit system;
      overlays = (import ../overlays { inherit inputs lib; });
    });
  # pkgsForSystem = system: (import nixpkgs {inherit system;});
  forSystem = f: system: f system (pkgsForSystem system);

  ## usage forAllSystems (system: pkgs: {...});
  forAllSystems = f: genAttrs supportedSystems (forSystem f);

  evalTreeFmt = import ./treefmt.nix treefmt-nix;

  oizysFlake = {
    templates = {
      dev = {
        path = ../templates/dev;
        description = "a basic dev shell";
      };
      default = self.templates.dev;
    };
    nixosModules = listToAttrs (findModulesList ../modules);
    nixosConfigurations = mapAttrs (name: _: mkSystem name) (readDir ../hosts);
    packages = forAllSystems (
      system: pkgs:
      {
        default = self.packages.${system}.oizys;
        iso = (mkIso system).config.system.build.isoImage;
      }
      // (import ../pkgs {
        inherit
          system
          pkgs
          lib
          inputs
          ;
      })
    );

    devShells = forAllSystems (
      system: pkgs: {
        oizys = pkgs.mkShell {
          packages = with pkgs; [
            openssl
            nim
            nim-atlas
          ];
        };
      }
    );

    checks = forAllSystems (
      _: pkgs: {
        formatter = (evalTreeFmt pkgs).config.build.check self;
      }
    );

    formatter = forAllSystems (_: pkgs: (evalTreeFmt pkgs).config.build.wrapper);
  };
in
{
  inherit oizysFlake;
}
