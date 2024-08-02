{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.oizys.desktop.enable {
    environment.systemPackages =
      [ (flake.pkg "f1multiviewer") ]
      ++ (with pkgs; [
        wezterm
        alacritty

        xfce.thunar

        inkscape
        gimp

        zotero

        libreoffice-qt
        hunspell # spell check for libreoffice

        (catppuccin-gtk.override {
          accents = [ "rosewater" ];
          variant = "mocha";
        })
      ]);
  };
}
