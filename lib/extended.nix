final: prev: let
  runes = import ../modules/runes;
in {
  mkIfIn = name: list: prev.mkIf (builtins.elem name list);
  mkRune = {
    rune,
    number ? "6",
    runeKind ? "braille",
  }:
    "[1;3${number}m\n" + runes.${rune}.${runeKind} + "\n[0m";
}
