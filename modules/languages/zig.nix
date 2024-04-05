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
  zls = inputs.zls.outputs.packages.${pkgs.system}.default;
in {
  config = mkIfIn "zig" cfg {
    environment.systemPackages = [zig zls];
  };
}
