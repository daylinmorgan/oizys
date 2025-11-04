inputs@{
  nixpkgs,
  treefmt-nix,
  crane,
  self,
  ...
}:
let
  lib = (nixpkgs.lib.extend (import ./extended.nix inputs));

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib) genAttrs findModulesList;
  inherit (lib.data) substituters;
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
      rec {
        default = oizys-nim;
        oizys = oizys-nim;
        oizys-nim = pkgs.callPackage ../pkgs/oizys {
          inherit (substituters) substituters trusted-public-keys;
        };
        oizys-rs = pkgs.callPackage ../pkgs/oizys-rs {
          inherit substituters;
          inherit (inputs) crane;
        };
        iso-x86_64-linux = (mkIso "x86_64-linux").config.system.build.isoImage;
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
        oizys-rs = (crane.mkLib pkgs).devShell {
          inputsFrom = [
            self.packages.${system}.oizys
          ];
          packages = with pkgs; [
            rust-analyzer
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
