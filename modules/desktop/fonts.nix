{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.desktop;
in {
  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    fonts.packages = with pkgs; [
      (nerdfonts.override {fonts = ["FiraCode"];})
    ];
  };
}
