{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.oizys.languages;
in {
  config = mkIf (builtins.elem "nim" cfg) {
    environment.systemPackages = with pkgs; [
      nim

      nim-atlas
      nimble
      nimlsp
    ];
  };
}
