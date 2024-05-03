{
  inputs,
  self,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixVersions.latest;
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
    inputs.pinix.packages.${pkgs.system}.default
  ];

  programs.nix-index-database.comma.enable = true;

  # nix-index didn't like this being enabled?
  programs.command-not-found.enable = false;

  nix.settings = {
    trusted-users = ["@wheel"];
    accept-flake-config = true;

    # substituters = [
    #   "https://daylin.cachix.org"
    # ];
    # trusted-public-keys = [
    #   "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
    # ];
  };
}
