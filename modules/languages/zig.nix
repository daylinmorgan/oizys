{
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in
{
  config = mkIfIn "zig" cfg {
    environment.systemPackages = [
      (flake.pkgs "zig-overlay").master
      (flake.pkg "zls")
    ];
  };
}
