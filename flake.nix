{
  description = "An example NixOS configuration";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/master"; };
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = inputs:
    /* ignore:: */
    let ignoreme = ({ config, lib, ... }: with lib; { system.nixos.revision = mkForce null; system.nixos.versionSuffix = mkForce "pre-git"; }); in
    {
      nixosConfigurations = {

        nixos = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            inputs.nix-ld.nixosModules.nix-ld

          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
