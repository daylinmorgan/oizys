{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cli;
in {
  options.cli.enable = mkEnableOption "cli";
  config = mkIf cfg.enable {
    programs.direnv.enable = true;
    environment.sessionVariables = {
      DIRENV_LOG_FORMAT = "[2mdirenv: %s[0m";
    };

    environment.systemPackages = with pkgs; [
      chezmoi
      zoxide
      lsd
      fzf

      # utils
      fd
      bat
      delta
      ripgrep

      btop
    ];
  };
}
