{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkIfIn flakeVer;

  version = flakeVer inputs.roc;
  cfg = config.oizys.languages;
  rocPkgs = inputs.roc.packages.${pkgs.system};
  # I'm setting the versions so the changes are more apparent as flake is updated
  roc = rocPkgs.cli.overrideAttrs {
    inherit version;

  };
  lang-server = rocPkgs.lang-server.overrideAttrs { inherit version; };

in
{
  config = mkIfIn "roc" cfg {
    environment.systemPackages = [
      roc
      lang-server
    ];
  };
}
