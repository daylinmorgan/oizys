{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages;
in {
  options.languages.misc = mkEnableOption "go + rustup";
  config = mkIf cfg.misc {
    environment.systemPackages = with pkgs; [
      go
      rustup
    ];
  };
}
