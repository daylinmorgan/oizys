{
  description = "daylinmorgan-nixcfg";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    hyprland.url = "github:hyprwm/Hyprland/main";
    hyprland-contrib.url = "github:hyprwm/contrib";
    wezterm.url = "github:wez/wezterm?dir=nix";
  };

  nixConfig = {
    extra-substituters = [ "https://daylin.cachix.org"];
    extra-trusted-public-keys = ["daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="];
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    lib = import ./lib {inherit inputs nixpkgs;};
  in {
    nixosModules = builtins.listToAttrs (lib.findModules ./modules);
    nixosConfigurations = lib.mapHosts ./hosts;
  };
}
