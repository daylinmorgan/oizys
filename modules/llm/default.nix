{
  pkgs,
  config,
  mkOizysModule,
  flake,
  ...
}:

let
  selfPackages = (flake.pkgs "self");
  pyWithLlm = (
    pkgs.python3.withPackages (_: [
      selfPackages.llm
      selfPackages.llm-claude-3
    ])
  );
  llm-with-plugins = (
    pkgs.writeShellScriptBin "llm" ''
      exec ${pyWithLlm}/bin/llm "$@"
    ''
  );
in
mkOizysModule config "llm" {
  environment.systemPackages = [ llm-with-plugins ];
}
