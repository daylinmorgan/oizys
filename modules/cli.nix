{
  inputs,
  pkgs,
  ...
}: {
  programs.direnv.enable = true;
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
}
