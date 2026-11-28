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
  config = mkIfIn "crystal" cfg {
    environment.systemPackages = with pkgs; [
      crystal
      shards
    ];
  };
}
