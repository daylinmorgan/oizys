inputs: final: prev:
let
  inherit (builtins)
    listToAttrs
    substring
    replaceStrings
    map
    filter
    attrNames
    readDir
    ;
  inherit (final)
    concatStringsSep
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    types
    splitString
    trim
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

  # split a string on newlines and pipes to generate list
  # "opt1|opt2" |> listify -> ["opt1" "opt2"]
  # ''
  # opt1
  # opt2|opt3
  # '' |> listify ["opt1" "opt2" "opt3"]
  listify =
    s:
    s
    |> replaceStrings [ "\n" ] [ "|" ]
    |> splitString "|"
    |> filter (s': s' != "")
    |> map (s': trim s');

  # ["a" "b"] -> {a.enable = true; b.enable = true;}
  enableAttrs =
    attrs:
    attrs
    |> map (attr: {
      name = attr;
      value = enabled;
    })
    |> listToAttrs;

  # ["a" "b"] -> {a.enable = false; b.enable = false;}
  disableAttrs =
    attrs:
    attrs
    |> map (attr: {
      name = attr;
      value = disabled;
    })
    |> listToAttrs;

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

  isNixFile = p: p |> hasSuffix ".nix";
  isDefaultNixFile = p: p |> hasSuffix "default.nix";
  # filterNotDefaultNixFile = paths: filter (p: !(isDefaultNixFile p) && (isNixFile p)) paths;
  filterNotDefaultNixFile = paths: paths |> filter (p: !(isDefaultNixFile p) && (isNixFile p));
  # listNixFilesRecursive = dir: filterNotDefaultNixFile (listFilesRecursive dir);
  listNixFilesRecursive = dir: dir |> listFilesRecursive |> filterNotDefaultNixFile;

  # defaultLinuxPackage = flake: flake.packages.x86_64-linux.default;
  # defaultPackageGeneric = system: flake: "${flake}.packages.${system}.default";
  pkgsFromSystem = system: flake: inputs."${flake}".packages."${system}";
  pkgFromSystem = system: flake: (pkgsFromSystem system flake).default;
  overlayFrom = flake: inputs."${flake}".overlays.default;
  nixosModuleFrom = flake: inputs."${flake}".nixosModules.default;
  flakeFromSystem = system: {
    overlay = overlayFrom;
    module = nixosModuleFrom;
    pkgs = pkgsFromSystem system;
    pkg = pkgFromSystem system;
  };

  loadOverlays =
    inputs: dir:
    readDir dir
    |> attrNames
    |> filter (f: f != "default.nix")
    |> map (f: import (../overlays + "/${f}") { inherit inputs; });

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
    listify
    loadOverlays
    ;
}
