{
  pkgs,
  config,
  lib,
  enabled,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.oizys.desktop.enable {
    qt = enabled // {
      platformTheme = "qt5ct";
      # style = "kvantum";
    };

    # For some reason it's not linked unless I include this.
    # Though it's possible if I enabled plasma than it would be.
    environment.pathsToLink = [ "/share/Kvantum" ];

    environment.systemPackages = with pkgs; [
      (catppuccin-gtk.override {
        accents = [ "pink" ];
        variant = "mocha";
      })

      (catppuccin-kvantum.override {
        variant = "mocha";
        accent = "pink";
      })

      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.okular
      libsForQt5.qt5ct
      papirus-icon-theme

      pcmanfm
      alacritty # backup to ghostty

      inkscape
      adwaita-icon-theme # needed for icons in inkscape

      gimp

      zotero

      libreoffice-qt
      hunspell # spell check for libreoffice
    ];

  };
}
