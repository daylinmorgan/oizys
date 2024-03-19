final: prev: let
  inherit (final) hasSuffix;
  runes = import ../modules/runes;
in rec {
  enabled = {enable = true;};
  disabled = {enable = false;};
  
  # ["a" "b"] -> {a.enable = true; b.enable = true;}
  enableAttrs = attrs: builtins.listToAttrs (map (attr: {name =  attr; value = enabled; }) attrs);
  # ["a" "b"] -> {a.enable = false; b.enable = false;}
  disableAttrs = attrs: builtins.listToAttrs (map (attr: {name =  attr; value = disabled; }) attrs);

  isNixFile = path: hasSuffix ".nix" path;
  mkIfIn = name: list: prev.mkIf (builtins.elem name list);
  mkRune = {
    rune,
    number ? "6",
    runeKind ? "braille",
  }:
    "[1;3${number}m\n" + runes.${rune}.${runeKind} + "\n[0m";
}
