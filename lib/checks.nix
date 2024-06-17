{ inputs, system }:
let
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.lix-module.overlays.default
      inputs.hyprland-contrib.overlays.default
      inputs.nixpkgs-wayland.overlay
    ];
  };
in
{
  makePackages =
    pkgs.runCommandLocal "build-third-party"
      {
        src = ./.;
        nativeBuildInputs = [
          pkgs.pixi
          pkgs.swww
          pkgs.xdg-desktop-portal-hyprland
          pkgs.nixVersions.stable

          inputs.tsm.packages.${pkgs.system}.default
          inputs.hyprman.packages.${pkgs.system}.default

          inputs.roc.packages.${pkgs.system}.full # cli + lang_server

          inputs.zls.outputs.packages.${pkgs.system}.default
          inputs.zig2nix.outputs.packages.${pkgs.system}.zig.master.bin
        ];
      }
      ''
        mkdir "$out"
      '';

}
