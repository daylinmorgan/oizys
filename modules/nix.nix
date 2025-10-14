{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.data) substituters lixVersion;
in
{
  # imports = [ (flake.module "lix-module") ];
  nix.package = pkgs.lixPackageSets.${lixVersion}.lix;

  nixpkgs.config.allowUnfree = true;
  nix = {
    optimise.automatic = true;
    gc = {
      # automatic = true; removed in favor of programs.nh.clean
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # use the same nixpkgs for nix run "nixpkgs#hello" style commands
    registry.nixpkgs.flake = inputs.nixpkgs;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
      ];
      use-xdg-base-directories = true;
      trusted-users = [ "@wheel" ];
      accept-flake-config = false;

    }
    // substituters;
  };
}
