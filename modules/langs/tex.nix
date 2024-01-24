{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages.tex;
in {
  options.languages.tex.enable = mkEnableOption "tex";
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      texlive.combined.scheme-full
    ];
  };
}
