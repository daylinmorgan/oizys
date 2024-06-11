{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    mdDoc
    ;
in
{
  imports = [
    ./misc.nix
    ./nim.nix
    ./node.nix
    ./nushell.nix
    ./python.nix
    ./tex.nix
    ./zig.nix
  ];
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
