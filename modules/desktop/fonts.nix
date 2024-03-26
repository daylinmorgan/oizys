{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.oizys.desktop.enable {
    fonts.fontconfig.enable = true;
    fonts.packages = with pkgs; [
      (nerdfonts.override {fonts = ["FiraCode"];})
      recursive
    ];
  };
}
