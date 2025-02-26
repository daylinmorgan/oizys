{
  config,
  flake,
  mkOizysModule,
  ...
}:

mkOizysModule config "llm" {
  environment.systemPackages = [ (flake.pkgs "self").llm];
}
