{
  description = "An example NixOS configuration";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/master"; };
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      # build with your own instance of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = inputs:
    {
      nixosConfigurations = {

        nixos-vm = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./overlays.nix
            ./environment.nix
            inputs.hyprland.nixosModules.default
            { programs.hyprland.enable = true; }
            inputs.nix-ld.nixosModules.nix-ld
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
