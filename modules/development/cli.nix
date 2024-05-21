{
  inputs,
  pkgs,
  config,
  mkDefaultOizysModule,
  ...
}:
mkDefaultOizysModule config "cli" {
  programs.direnv.enable = true;

  environment.systemPackages = (with pkgs; [
    chezmoi
    zoxide
    lsd
    fzf
    eza

    # utils
    fd
    bat
    delta
    ripgrep

    glow
    btop
  ]
    ) ++ [
    inputs.tsm.packages.${pkgs.system}.tsm]
  ;
}
