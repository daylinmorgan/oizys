{
  inputs,
  pkgs,
  lib,
  enabled,
  flake,
  ...
}:
let
  inherit (lib) makeBinPath;
in
{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  nixpkgs.config.allowUnfree = true;
  # nix.package = pkgs.nixVersions.latest;
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      use-xdg-base-directories = true
    '';

    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # use the same nixpkgs for nix run "nixpkgs#hello" style commands
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html#_nix-shell_vs_nix_shell
  # use the same nixpkgs for nix-shell -p hello style commands
  # I don't know that this is necesary...
  # nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" ];
  # environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

  environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
    pkgs.nix-output-monitor

    (flake.pkg "self")
  ];

  programs.nix-index-database.comma = enabled;

  # nix-index didn't like this being enabled?
  programs.command-not-found.enable = false;

  # I'm getting errors related to a non-existent nix-index?
  programs.nix-index.enableZshIntegration = false;
  programs.nix-index.enableBashIntegration = false;
  programs.nix-index.enableFishIntegration = false;

  system.activationScripts.diff = ''
    if [[ -e /run/current-system ]]; then
      PATH=$PATH:${
        makeBinPath [
          pkgs.nvd
          pkgs.nix
        ]
      }
      nvd diff /run/current-system "$systemConfig"
    fi
  '';

  nix.settings = {
    trusted-users = [ "@wheel" ];
    accept-flake-config = true;
  };
}
