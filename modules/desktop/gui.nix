{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.oizys.desktop.enable {
    environment.systemPackages = with pkgs; [
      wezterm
      alacritty

      xfce.thunar

      inkscape
      gimp

      zotero

      libreoffice-qt
      hunspell # spell check for libreoffice

      (catppuccin-gtk.override {
        accents = ["rosewater"];
        variant = "mocha";
      })
    ];
  };
}
