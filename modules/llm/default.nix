{
  pkgs,
  config,
  mkOizysModule,
  # enabled,
  ...
}:

let
  inherit (pkgs) python3Packages;
  # llm-ollama = python3Packages.callPackage ./llm-plugins/llm-ollama { };
  llm-claude3 = python3Packages.callPackage ./llm-plugins/llm-claude-3 { };
in

mkOizysModule config "llm" {
  # services.ollama = enabled;
  environment.systemPackages = with pkgs; [
    (python3.withPackages (ps: [
      ps.llm
      llm-claude3
    ]))
  ];
}
