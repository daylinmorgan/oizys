{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages;
in {
  options.languages.node = mkEnableOption "node";
  config = mkIf cfg.node {
    environment.systemPackages = with pkgs; [
      nodejs
      nodePackages.pnpm
    ];
  };
}
