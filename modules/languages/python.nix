{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.oizys.languages;
in {
  config = mkIf (builtins.elem "python" cfg) {
    environment.systemPackages = let
      python = pkgs.python3.withPackages (ps: with ps; [pip]);
    in
      with pkgs; [
        # https://github.com/Mic92/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
        (pkgs.writeShellScriptBin "python" ''
          export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
          exec ${python}/bin/python "$@"
        '')

        (pkgs.writeShellScriptBin "python3" ''
          export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
          exec ${python}/bin/python "$@"
        '')

        (python3.withPackages (ps: with ps; [pip]))
        micromamba
      ];
  };
}
