{
  pkgs,
  config,
  mkOizysModule,
  flake,
  ...
}:

mkOizysModule config "llm" {
  environment.systemPackages = with pkgs; [
    (python3.withPackages (ps:
      with (flake.pkgs "self");
      [
        llm
        llm-claude-3
      ]
    ))
  ];
}
