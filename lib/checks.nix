{
  inputs,
  system,
  lib,
}:
let
  inherit (builtins) map;
  inherit (lib) pkgFromSystem pkgsFromSystem overlayFrom;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = map [
      "lix-module"
      "hyprland-contrib"
      "nixpkgs-wayland"
    ] overlayFrom;
  };
  pkgsFrom = pkgsFromSystem system;
  pkgFrom = pkgFromSystem system;
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
          ] pkgFrom)
          ++ (with pkgsFrom "hyprland"; [
            default
            xdg-desktop-portal-hyprland
          ])
          ++ [
            (pkgsFrom "roc").full
            (pkgsFrom "zig2nix").zig.master.bin
          ];
      }
      ''
        mkdir "$out"
      '';

}
