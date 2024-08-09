{
  inputs,
  system,
  lib,
  self,
}:
let
  inherit (lib) flakeFromSystem attrValues;

  flake = flakeFromSystem system;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (flake.overlay "lix-module")
      (flake.overlay "hyprland-contrib")
      (flake.overlay "nixpkgs-wayland")
    ];
  };

  hyprPackages = with (flake.pkgs "hyprland"); [
    default
    xdg-desktop-portal-hyprland
  ];

  # TODO: start using pipes once support lands in nixd
  # selfPackages = self.packages.${pkgs.system} |> attrValues;
  selfPackages = (attrValues self.packages.${pkgs.system});
in
{
  makePackages =
    pkgs.runCommandLocal "build-third-party"
      {
        nativeBuildInputs =
          # packages from overlays
          (with pkgs; [
            swww
            # nixVersions.git
          ])
          ++ [
            (flake.pkgs "roc").full
            (flake.pkgs "zig-overlay").master
            (flake.pkg "zls")
          ]
          ++ hyprPackages
          ++ selfPackages;
      }
      ''
        mkdir "$out"
      '';

}
