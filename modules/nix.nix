{
  inputs,
  self,
  pkgs,
  enabled,
  ...
}:
{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  nixpkgs.config.allowUnfree = true;
  # nix.package = pkgs.nixVersions.latest;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
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
    self.packages.${pkgs.system}.default
  ];

  programs.nix-index-database.comma = enabled;

  # nix-index didn't like this being enabled?
  programs.command-not-found.enable = false;

  nix.settings = {
    trusted-users = [ "@wheel" ];
    accept-flake-config = true;
  };
}
