{
  pkgs,
  config,
  enabled,
  mkOizysModule,
  ...
}:

let
  inherit (pkgs) python3Packages;
  llm-ollama = python3Packages.callPackage ./llm-plugins/llm-ollama { };
  llm-claude3 = python3Packages.callPackage ./llm-plugins/llm-claude-3 { };
  llm = (
    pkgs.llm.withPlugins [
      llm-ollama
      llm-claude3
    ]
  );
in

mkOizysModule config "llm" {
  services.ollama = enabled;
  environment.systemPackages = [ llm ];
}
