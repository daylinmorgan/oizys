{
  pkgs,
  zig2nix,
  lib,
  ...
}:
        (zig2nix.outputs.zig-env.${pkgs.system} {
          zig = zig2nix.outputs.packages.${pkgs.system}.zig.master.bin;
        }).package {
  name = "oizys";
  src = lib.cleanSource ./.;
}
