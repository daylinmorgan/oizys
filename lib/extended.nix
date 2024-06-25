final: prev:
let
  inherit (builtins) listToAttrs substring;
  inherit (final)
    concatStringsSep
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
let
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
  isNixFile = path: hasSuffix ".nix" path;

in
{
  inherit
    enabled
    disabled
    enableAttrs
    disableAttrs
    mkOizysModule
    mkDefaultOizysModule
    mkDate
    isNixFile
    mkIfIn
    ;
}
