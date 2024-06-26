{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    literalExpression

    mdDoc
    listNixFilesRecursive
    ;
in
{
  imports = listNixFilesRecursive ./.;
  options.oizys.languages = mkOption {
    type = with types; (listOf str);
    description = mdDoc ''
      List of programming languages to enable.
    '';
    default = [ ];
    example = literalExpression ''
      [
        "python"
        "nim"
      ]
    '';
  };
}
