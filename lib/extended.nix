inputs: final: prev:
let
  inherit (builtins) listToAttrs substring filter;
  inherit (final)
    concatStringsSep
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (final.filesystem) listFilesRecursive;
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

  flakeVer =
    flake: "${flake.shortRev or flake.dirtyShortRev}-${mkDate (toString flake.lastModifiedDate)}";

  isNixFile = p: hasSuffix ".nix" p;
  isDefaultNixFile = p: hasSuffix "default.nix" p;
  filterNotDefaultNixFile = paths: filter (p: !(isDefaultNixFile p) && (isNixFile p)) paths;
  listNixFilesRecursive = dir: filterNotDefaultNixFile (listFilesRecursive dir);

  # defaultLinuxPackage = flake: flake.packages.x86_64-linux.default;
  # defaultPackageGeneric = system: flake: "${flake}.packages.${system}.default";
  pkgsFromSystem = system: flake: inputs."${flake}".packages."${system}";
  pkgFromSystem = system: flake: (pkgsFromSystem system flake).default;
  overlayFrom = flake: inputs."${flake}".overlays.default;
  flakeFromSystem = system: {
    overlay = overlayFrom;
    pkgs = pkgsFromSystem system;
    pkg = pkgFromSystem system;
  };
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
    mkIfIn
    isNixFile
    listNixFilesRecursive
    flakeVer
    pkgsFromSystem
    pkgFromSystem
    overlayFrom
    flakeFromSystem
    ;
}
