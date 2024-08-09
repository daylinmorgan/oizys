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
  config = mkIfIn "nushell" cfg { environment.systemPackages = with pkgs; [ nushell ]; };
}
