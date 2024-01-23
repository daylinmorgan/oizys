{config, lib,pkgs,...}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages.python;
in
{
  options.languages.python.enable = mkEnableOption "python";
  config = mkIf cfg.enable {

  environment.systemPackages = with pkgs; [
    # https://github.com/Mic92/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
    (pkgs.writeShellScriptBin "python" ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${pkgs.python3}/bin/python "$@"
    '')

    (pkgs.writeShellScriptBin "python3" ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${pkgs.python3}/bin/python "$@"
    '')

    (python3.withPackages (ps: with ps; [pip]))
    micromamba
  ];

};
}
