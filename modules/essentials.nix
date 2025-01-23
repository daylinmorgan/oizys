{
  inputs,
  pkgs,
  self,
  flake,
  enabled,
  ...
}:
{
  imports = with self.nixosModules; [ git ];
  programs.zsh = enabled;
  environment.systemPackages = with pkgs; [
    tmux
    unzip
    zip
    less
    gnumake
    gcc
    file

    wget
    curl
    htop

    (flake.pkg "self")

    pkgs.nix-output-monitor
  ];

  nixpkgs.config.allowUnfree = true;
  nix.package = (flake.pkgs "self").lix;

  nix = {
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # use the same nixpkgs for nix run "nixpkgs#hello" style commands
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
      ];
      use-xdg-base-directories = true;
      trusted-users = [ "@wheel" ];
      accept-flake-config = true;
      extra-substituters = [
        "https://attic.dayl.in/oizys"
        # "https://nixpkgs-wayland.cachix.org"
        # "https://hyprland.cachix.org"
        # "https://daylin.cachix.org"
      ];
      extra-trusted-public-keys = [
        "oizys:DSw3mwVMM/Y+PXSVpkDlU5dLwlORuiJRGPkwr5INSMc="
        # "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        # "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
      ];
    };
  };
}
