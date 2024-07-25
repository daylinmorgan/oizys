{
  inputs,
  pkgs,
  config,
  lib,
  pkgFrom,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.oizys.desktop.enable {
    environment.systemPackages =
      [ (pkgFrom "f1multiviewer") ]
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
