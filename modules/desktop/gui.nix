{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.desktop;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.wezterm.packages.${pkgs.system}.default
      alacritty

      inkscape
      gimp

      libreoffice-qt
      hunspell # spell check for libreoffice

      (vivaldi.override {
        commandLineArgs = [
          "--force-dark-mode"
        ];
        proprietaryCodecs = true;
      })
    ];
  };
}
