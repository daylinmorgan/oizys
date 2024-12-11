{
  config,
  pkgs,
  mkOizysModule,
  ...
}:
mkOizysModule config "utils" {
  # a grab bag of classic utils I probably want installed by default
  environment.systemPackages = with pkgs; [
    feh
    jq
  ];
}
