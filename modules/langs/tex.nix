{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages;
in {
  options.languages.tex = mkEnableOption "tex";
  config = mkIf cfg.tex {
    environment.systemPackages = with pkgs; [
      texlive.combined.scheme-full
    ];
  };
}
