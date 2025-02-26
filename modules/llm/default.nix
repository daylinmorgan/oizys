{
  config,
  flake,
  mkOizysModule,
  ...
}:

mkOizysModule config "llm" {
  environment.systemPackages = [ (flake.pkg "llm-nix") ];
}
