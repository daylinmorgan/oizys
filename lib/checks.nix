{
  inputs,
  system,
  lib,
}:
let
  inherit (builtins) map;
  inherit (lib) flakeFromSystem;

  flake = flakeFromSystem system;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (flake.overlay "lix-module")
      (flake.overlay "hyprland-contrib")
      (flake.overlay "nixpkgs-wayland")
    ];
  };
  myPackages = map [
    "tsm"
    "hyprman"
    "zls"
  ] flake.pkg;

  hyprPackages = with (flake.pkgs "hyprland"); [
    default
    xdg-desktop-portal-hyprland
  ];
in
{
  makePackages =
    pkgs.runCommandLocal "build-third-party"
      {
        src = ./.;
        nativeBuildInputs =
          (with pkgs; [
            pixi
            swww
            nixVersions.stable
          ])
          ++ [
            (flake.pkgs "roc").full
            (flake.pkgs "zig2nix").zig.master.bin
          ]
          ++ myPackages
          ++ hyprPackages;

      }
      ''
        mkdir "$out"
      '';

}
