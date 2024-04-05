{
  inputs,
  pkgs,
  config,
  mkDefaultOizysModule,
  ...
}:
mkDefaultOizysModule config "cli" {
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

    glow
    btop
    inputs.tsm.packages.${pkgs.system}.tsm
  ];
}
