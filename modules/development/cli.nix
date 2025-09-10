{
  pkgs,
  config,
  enabled,
  mkDefaultOizysModule,
  flake,
  ...
}:
mkDefaultOizysModule config "cli" {

  programs.direnv = enabled // {
    settings.global.hide_env_diff = true;
  };

  environment.systemPackages =
    (with pkgs; [
      parallel
      chezmoi
      zoxide
      lsd
      fzf
      eza

      # utils
      fd
      bat
      ripgrep

      glow
      btop
      gdu
    ])
    ++ [ (flake.pkg "tsm") ];
}
