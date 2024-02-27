{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.oizys.cli;
in {
  options.oizys.cli.enable = mkOption {
    default = true;
    description = "Whether to enable cli.";
    type = types.bool;
  };

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
