{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    isNixFile
    literalExpression
    mdDoc
    ;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (builtins) filter;

  listNixFilesRecursive =
    dir: filter (f: (f != ./default.nix) && (isNixFile f)) (listFilesRecursive dir);
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
