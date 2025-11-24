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
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
      kdePackages.okular
      papirus-icon-theme

      pcmanfm
      alacritty # backup to ghostty

      inkscape
      adwaita-icon-theme # needed for icons in inkscape

      gimp

      zotero

      libreoffice-qt
      hunspell # spell check for libreoffice

      feh

      (pkgs.writeShellScriptBin "dragon" "exec -a $0 ${dragon-drop}/bin/dragon-drop $@")
    ];

  };
}
