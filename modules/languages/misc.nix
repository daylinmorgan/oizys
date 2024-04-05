{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
  zig = inputs.zig2nix.outputs.packages.${pkgs.system}.zig.master.bin;
in {
  config = mkIfIn "misc" cfg {
    environment.systemPackages = with pkgs;
      [
        go
        rustup
      ]
      ++ [zig];
  };
}
