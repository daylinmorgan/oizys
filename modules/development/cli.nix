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

  environment.etc = {
    "direnv/direnv.toml".text = ''
      [global]
      hide_env_diff=true
    '';
  };

  environment.systemPackages =
    (with pkgs; [
      chezmoi
      zoxide
      lsd
      fzf
      eza
      oh-my-posh

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
