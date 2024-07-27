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
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    use-xdg-base-directories = true
  '';

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

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
