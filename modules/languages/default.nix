{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types literalExpression mdDoc;
in {
  imports = [./nim.nix ./tex.nix ./misc.nix ./node.nix ./python.nix];
  options.oizys.languages = mkOption {
    type = with types; (listOf str);
    description = lib.mdDoc ''
      List of programming languages to enable.
    '';
    default = [];
    example = literalExpression ''
      [
        "python"
        "nim"
      ]
    '';
  };
}
