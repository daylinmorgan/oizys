{
  nixpkgs,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages;
in {
  options.languages.nim = mkEnableOption "nim";
  config = mkIf cfg.nim {
    nixpkgs.overlays = [
      (import ../../overlays/nim {})
      (import ../../overlays/nimlsp {})
      (import ../../overlays/nimble {})
      (import ../../overlays/nim-atlas {})
    ];

    environment.systemPackages = with pkgs; [
      nim-atlas
      nim
      nimble
      nimlsp
    ];
  };
}
