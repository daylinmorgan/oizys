{
  config,
  lib,
  pkgsFrom,
  pkgFrom,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
  zig = (pkgsFrom "zig2nix").zig.master.bin;
  zls = (pkgFrom "zls").overrideAttrs { nativeBuildInputs = [ zig ]; };
in
{
  config = mkIfIn "zig" cfg {
    environment.systemPackages = [
      zig
      zls
    ];
  };
}
