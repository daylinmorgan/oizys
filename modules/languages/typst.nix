{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in
{
  config = mkIfIn "typst" cfg {
    environment.systemPackages = with pkgs; [
      typst
      tinymist
    ];
  };
}
