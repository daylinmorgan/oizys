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
  config = mkIfIn "nim" cfg {
    environment.systemPackages = with pkgs; [
      nim
      nph

      nim-atlas
      nimble
      nimlangserver
    ];
  };
}
