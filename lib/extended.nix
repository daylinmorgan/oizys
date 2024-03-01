final: prev: let
  inherit (final) hasSuffix;
  runes = import ../modules/runes;
in {

  isNixFile = path: hasSuffix ".nix" path;
  mkIfIn = name: list: prev.mkIf (builtins.elem name list);
  mkRune = {
    rune,
    number ? "6",
    runeKind ? "braille",
  }:
    "[1;3${number}m\n" + runes.${rune}.${runeKind} + "\n[0m";
}
