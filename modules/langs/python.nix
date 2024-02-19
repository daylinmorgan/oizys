{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages;
in {
  options.languages.python = mkEnableOption "python";
  config = mkIf cfg.python {
    environment.systemPackages = 
    let python = pkgs.python3.withPackages(ps: with ps; [pip]);
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

      # (python3.withPackages (ps: with ps; [pip]))
      micromamba
    ];
  };
}
