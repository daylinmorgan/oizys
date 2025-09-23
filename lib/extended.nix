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
    readFile
    pathExists
    length
    ;
  inherit (final)
    concatStringsSep
    hasSuffix
    hasInfix
    mkEnableOption
    mkIf
    mkOption
    types
    hasPrefix
    splitString
    removePrefix
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

  ## convert a list of flakes to { name = packageAttr; }
  flakesToPackagesAttrs =
    system: flakes:
    listToAttrs (
      map (name: {
        inherit name;
        value = pkgFromSystem system name;
      }) flakes
    );

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
    toPackageAttrs = flakesToPackagesAttrs system;
  };

  loadOverlays =
    inputs: dir:
    readDir dir
    |> attrNames
    |> filter (f: f != "default.nix")
    |> map (
      f:
      import (../overlays + "/${f}") {
        inherit inputs;
        lib = final;
      }
    );

  selfPkgsOverlays =
    final: packages:
    packages
    |> map (name: {
      inherit name;
      value = inputs.self.packages."${final.system}"."${name}";
    })
    |> listToAttrs;

  loadNixpkgOverlay = final: name: {
    inherit name;
    value = import inputs."${name}" {
      inherit (final) system config;
    };
  };

  loadNixpkgOverlays =
    final:
    inputs
    |> attrNames
    |> filter (name: (hasInfix "nixpkgs" name) && (name != "nixpkgs"))
    |> map (loadNixpkgOverlay final)
    |> listToAttrs;

  # overlay packages from a separate nixpkgs input then the default one
  pkgsFromNixpkgs =
    final: nixpkgsInput: packageNames:
    let
      nixpkgs = (
        import inputs."${nixpkgsInput}" {
          inherit (final) system config;
        }
      );
    in
    packageNames
    |> map (name: {
      inherit name;
      value = nixpkgs."${name}";
    })
    |> listToAttrs;

  readLinesNoComment =
    f: f |> readFile |> splitString "\n" |> filter (line: !(hasPrefix "#" line) && line != "");

  pathFromHostName = host: ../. + "/hosts/${host}";
  hostFiles = host: host |> pathFromHostName |> listFilesRecursive |> filter isNixFile;
  hostSystem =
    host:
    let
      f = (host |> pathFromHostName) + "/settings/system";
    in
    if pathExists f then readLinesNoComment f else "x86_64-linux";

  # if the specified path doesn't exist returns an empty array
  tryReadLinesNoComment = f: if pathExists f then (readLinesNoComment f) else [ ];

  tryreadEnabledAttrsOrEmpty =
    p: p |> tryReadLinesNoComment |> (lines: if (length lines) > 0 then lines |> enableAttrs else { });

  oizysSettings =
    hostName:
    hostName
    |> pathFromHostName
    |> (
      p:
      {
        languages = tryReadLinesNoComment "${p}/settings/languages";
      }
      // (tryreadEnabledAttrsOrEmpty "${p}/settings/modules")
    );

  # convert the following:
  # ```txt
  # flake:utils
  # sops
  # graphviz
  # ```
  # to
  # ```nix
  # [
  #   (flake.pkg "utils")
  #   pkgs.sops
  #   pkgs.graphviz
  # ]
  # ```
  tryPkgsFromFile =
    {
      hostName,
      pkgs,
      flake ? flakeFromSystem pkgs.system,
    }:
    hostName
    |> pathFromHostName
    |> (p: "${p}/settings/pkgs")
    |> tryReadLinesNoComment
    |> map (
      line: if hasPrefix "flake:" line then (line |> removePrefix "flake:" |> flake.pkg) else pkgs.${line}
    );

  data = (import ./data.nix);
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
    pkgsFromNixpkgs
    overlayFrom
    selfPkgsOverlays
    flakeFromSystem
    listify
    loadOverlays
    loadNixpkgOverlays
    hostFiles
    hostSystem
    oizysSettings
    tryPkgsFromFile
    data
    ;
}
