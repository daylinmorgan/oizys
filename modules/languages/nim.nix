{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
  nimlangserver = pkgs.callPackage ../../pkgs/nimlangserver { };
in
{
  config = mkIfIn "nim" cfg {
    environment.systemPackages =
      with pkgs;
      [
        nim

        nim-atlas
        nimble
      ]
      ++ [ nimlangserver ];
  };
}
