{
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
    environment.systemPackages = with pkgs; [
      nim

      nim-atlas
      nimble
      nimlsp
    ];
  };
}
