final: prev:
let
  inherit (final)
    concatStringsSep
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (builtins) listToAttrs substring;
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
    listToAttrs (
      map (attr: {
        name = attr;
        value = enabled;
      }) attrs
    );
  # ["a" "b"] -> {a.enable = false; b.enable = false;}
  disableAttrs =
    attrs:
    listToAttrs (
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

  # generate date string with '-' from long date
  mkDate =
    longDate:
    (concatStringsSep "-" [
      (substring 0 4 longDate)
      (substring 4 2 longDate)
      (substring 6 2 longDate)
    ]);
}
