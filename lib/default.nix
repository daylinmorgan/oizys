inputs@{
  nixpkgs,
  treefmt-nix,
  self,
  ...
}:
let
  lib = nixpkgs.lib.extend (import ./extended.nix inputs);

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib)
    genAttrs
    loadOverlays
    ;

  inherit (import ./find-modules.nix { inherit lib; }) findModulesList;
  inherit (import ./generators.nix { inherit lib self inputs; }) mkIso mkSystem;
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = [ "x86_64-linux" ];

  substituters = (import ../lib/substituters.nix);

  forAllSystems =
    fn:
    genAttrs supportedSystems (
      system:
      fn (
        import nixpkgs {
          inherit system;
          overlays = (import ../overlays { inherit inputs loadOverlays; });
        }
      )
    );

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
      pkgs:
      rec {
        default = oizys;
        oizys = pkgs.callPackage ../pkgs/oizys {
          inherit (substituters) substituters trusted-public-keys;
        };
        iso-x86_64-linux = (mkIso "x86_64-linux").config.system.build.isoImage;
      }
      // (import ../pkgs { inherit pkgs lib inputs; })
    );

    devShells = forAllSystems (pkgs: {
      oizys = pkgs.mkShell {
        packages = with pkgs; [
          openssl
          nim
          self.packages.${pkgs.system}.nimble
        ];
      };
    });
    checks = forAllSystems (
      pkgs:
      import ./checks.nix {
        inherit inputs lib self;
        system = pkgs.system;
      }
      // {
        formatter = (evalTreeFmt pkgs).config.build.check self;
      }
    );
    formatter = forAllSystems (pkgs: (evalTreeFmt pkgs).config.build.wrapper);

    # use nixosConfigurations.$host.config.oizys.packages instead
    # hydraJobs = {
    #   systemPackages =
    #     (readDir ../hosts)
    #     |> mapAttrs (
    #       hostname: _:
    #       self.nixosConfigurations."${hostname}".config.environment.systemPackages
    #       |> map (drv: {
    #         name = drv.name;
    #         value = drv;
    #       })
    #       |> listToAttrs
    #     );
    #
    #   inherit (self) packages;
    # };
  };
in
{
  inherit oizysFlake;
}
