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
    overlays = map [
      "lix-module"
      "hyprland-contrib"
      "nixpkgs-wayland"
    ] flake.overlay;
  };
in
{
  makePackages =
    pkgs.runCommandLocal "build-third-party"
      {
        src = ./.;
        nativeBuildInputs =
          [
            pkgs.pixi
            pkgs.swww
            pkgs.nixVersions.stable
          ]
          ++ (map [
            "tsm"
            "hyprman"
            "zls"
          ] flake.pkg)
          ++ (with flake.pkgs "hyprland"; [
            default
            xdg-desktop-portal-hyprland
          ])
          ++ [
            (flake.pkgs "roc").full
            (flake.pkgs "zig2nix").zig.master.bin
          ];
      }
      ''
        mkdir "$out"
      '';

}
