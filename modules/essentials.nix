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
    (flake.pkgs "self").oizys-rs

    sops
  ];

  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.lixPackageSets.stable.lix;

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
      accept-flake-config = true;

    }
    // (import ../lib/substituters.nix);
  };
}
