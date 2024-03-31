{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in {
  config = mkIfIn "misc" cfg {
    environment.systemPackages = with pkgs; [
      zig
      go
      rustup
    ];
  };
}
