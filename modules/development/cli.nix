{
  inputs,
  pkgs,
  config,
  enabled,
  mkDefaultOizysModule,
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
    ++ [ inputs.tsm.packages.${pkgs.system}.tsm ];
}
