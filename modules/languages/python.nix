{
  inputs,
  config,
  lib,
  pkgs,
  pkgFrom,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;

  python = pkgs.python3.withPackages (ps: with ps; [ pip ]);
  pixi = pkgFrom "pixi";
in
{
  config = mkIfIn "python" cfg {
    environment.systemPackages = [
      # https://github.com/Mic92/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
      (pkgs.writeShellScriptBin "python" ''
        export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
        exec ${python}/bin/python "$@"
      '')

      (pkgs.writeShellScriptBin "python3" ''
        export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
        exec ${python}/bin/python "$@"
      '')
      pixi

      # needed for viv to work
      pkgs.python3Packages.pip
      pkgs.micromamba
    ];
  };
}
