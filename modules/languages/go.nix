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
  config = mkIfIn "go" cfg {
    environment.systemPackages = with pkgs; [
      go
      gopls
    ];
  };
}
