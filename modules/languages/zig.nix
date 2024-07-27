{
  config,
  lib,
flake,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
  zig = (flake.pkgs "zig2nix").zig.master.bin;
  zls = (flake.pkg "zls").overrideAttrs { nativeBuildInputs = [ zig ]; };
in
{
  config = mkIfIn "zig" cfg {
    environment.systemPackages = [
      zig
      zls
    ];
  };
}
