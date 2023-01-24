{
  description = "An example NixOS configuration";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/master"; };
  };


  outputs = inputs:
    {
      nixosConfigurations = {

        nixos-vm = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules/configuration.nix
            ./modules/overlays.nix
            ./modules/environment.nix
          ];
        };
        jeran = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/jeran/configuration.nix
            ./modules/environment.nix
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
