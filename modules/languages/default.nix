{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types literalExpression mdDoc;
  cfg = config.oizys.languages;
in {
  imports = [./nim.nix ./tex.nix ./misc.nix ./node.nix ./python.nix];
  options.oizys.languages = mkOption {
    type = with types; nullOr (listOf str);
    description = lib.mdDoc ''
      List of programming languages to enable.
    '';
    default = null;
    example = literalExpression ''
      [
        "python"
        "nim"
      ]
    '';
  };
}
