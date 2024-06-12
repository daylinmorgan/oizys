{ lib, ... }:
let
  inherit (builtins)
  filter;
  inherit (lib)
    isNixFile
    mkOption
    types
    literalExpression
    mdDoc
    ;
    inherit (lib.filesystem)
    listFilesRecursive;
in
{
  imports = filter (f: (f != ./default.nix) && (isNixFile f)) (listFilesRecursive ./.);

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
