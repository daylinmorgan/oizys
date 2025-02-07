{
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIfIn;

  cfg = config.oizys.languages;
  rocPkgs = flake.pkgs "roc";
in
{
  config = mkIfIn "roc" cfg {
    environment.systemPackages = with rocPkgs; [
      cli
      lang-server
    ];
  };
}
