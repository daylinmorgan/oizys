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

  selfPackages = (attrValues self.packages.${pkgs.system});
in
# selfPackages = self.packages.${pkgs.system} |> attrValues;
{
  makePackages =
    pkgs.runCommandLocal "build-third-party"
      {
        src = ./.;
        nativeBuildInputs =
          # packages from overlays
          (with pkgs; [
            swww
            nixVersions.stable
          ])
          ++ [
            (flake.pkgs "roc").full
            (flake.pkgs "zig2nix").zig.master.bin
          ]
          ++ hyprPackages
          ++ selfPackages;
      }
      ''
        mkdir "$out"
      '';

}
