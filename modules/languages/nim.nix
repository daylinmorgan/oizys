{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in
{
  config = mkIfIn "nim" cfg {
    environment.systemPackages =
      (with pkgs; [
        nim
      ])
      ++ (with (flake.pkgs "self"); [
        nimlangserver
        # nph
        nimble
      ]);
  };
}
