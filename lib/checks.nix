{ inputs, pkgs }:
{

  makePackages =
    pkgs.runCommandLocal "build-third-party"
      {
        src = ./.;
        nativeBuildInputs = [
          pkgs.pixi
          pkgs.swww

          inputs.tsm.packages.${pkgs.system}.default
          inputs.hyprman.packages.${pkgs.system}.default

          inputs.roc.packages.${pkgs.system}.full
          inputs.roc.packages.${pkgs.system}.lang-server

          inputs.zls.outputs.packages.${pkgs.system}.default
          inputs.zig2nix.outputs.packages.${pkgs.system}.zig.master.bin
        ];
      }
      ''
        mkdir "$out"
      '';

}
