{
  inputs,
  pkgs,
  ...
}: {
  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["FiraCode"];})
  ];
  security.pam.services.swaylock = {};
  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.default;
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    swaylock
    brightnessctl

    # notifications
    libnotify
    dunst

    # screenshots
    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
    grim
    slurp

    eww-wayland
    rofi-wayland
    hyprpaper

    catppuccin-cursors.mochaDark
    pavucontrol
  ];
  nixpkgs.overlays =  [ inputs.nixpkgs-wayland.overlay ];
  # wayland extras
  nix.settings = {
    # add binary caches
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://hyprland.cachix.org"
    ];
  };
}
