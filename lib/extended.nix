final: prev:
let
  inherit (final)
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
rec {
  enabled = {
    enable = true;
  };
  disabled = {
    enable = false;
  };

  # ["a" "b"] -> {a.enable = true; b.enable = true;}
  enableAttrs =
    attrs:
    builtins.listToAttrs (
      map (attr: {
        name = attr;
        value = enabled;
      }) attrs
    );
  # ["a" "b"] -> {a.enable = false; b.enable = false;}
  disableAttrs =
    attrs:
    builtins.listToAttrs (
      map (attr: {
        name = attr;
        value = disabled;
      }) attrs
    );

  isNixFile = path: hasSuffix ".nix" path;
  mkIfIn = name: list: prev.mkIf (builtins.elem name list);

  mkOizysModule = config: attr: content: {
    options.oizys.${attr}.enable = mkEnableOption "enable ${attr} support";
    config = mkIf config.oizys.${attr}.enable content;
  };
  mkDefaultOizysModule = config: attr: content: {
    options.oizys.${attr}.enable = mkOption {
      default = true;
      description = "enable ${attr} support";
      type = types.bool;
    };
    config = mkIf config.oizys.${attr}.enable content;
  };
}
