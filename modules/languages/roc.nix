{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
  rocPkgs = inputs.roc.packages.${pkgs.system};
in
{
  config = mkIfIn "roc" cfg {
    environment.systemPackages = with rocPkgs; [
      full # cli + lang_server
    ];
  };
}
