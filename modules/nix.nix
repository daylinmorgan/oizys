{
  inputs,
  lib,
  ...
}:
let
  inherit (lib.data) substituters;
in
{
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
      # lix is getting strict...surely someone else will deal with these things in nixos/nixpkgs
      deprecated-features = [
        "or-as-identifier"
        "broken-string-escape"
      ];
      use-xdg-base-directories = true;
      trusted-users = [ "@wheel" ];
      accept-flake-config = false;

    }
    // substituters;
  };
}
