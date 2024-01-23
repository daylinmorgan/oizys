{
  input,
  pkgs,
  ...
}: {
  imports = [
    ./styx
  ];
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  environment.systemPackages = with pkgs; [
    nix-output-monitor
    alejandra
  ];

  nix.settings = {
    trusted-users = ["daylin"];
    substituters = [
      "https://daylin.cachix.org"
    ];
     trusted-public-keys = [
      "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
    ];
  };
}
