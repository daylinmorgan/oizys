{
  inputs,
  self,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    alejandra
    self.packages.${pkgs.system}.oizys
    inputs.pinix.packages.${pkgs.system}.default
  ];

  nix.settings = {
    trusted-users = ["@wheel"];
    accept-flake-config = true;

    substituters = [
      "https://daylin.cachix.org"
    ];
    trusted-public-keys = [
      "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
    ];
  };
}
