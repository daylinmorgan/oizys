{
  pkgs,
  config,
  enabled,
  mkDefaultOizysModule,
  flake,
  ...
}:
mkDefaultOizysModule config "cli" {

  programs.direnv = enabled;

  # I think I was overwriting what is generated with programs.direnv...
  # could these be added by using programs.direnv.settings?
  # environment.etc = {
  #   "direnv/direnv.toml".text = ''
  #     [global]
  #     hide_env_diff=true
  #   '';
  # };

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
