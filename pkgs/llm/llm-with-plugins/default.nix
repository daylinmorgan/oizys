{
  pkgs,
  ...
}:
let
  inherit (pkgs) python3Packages;
  llm = python3Packages.callPackage ../llm { };
  llm-claude-3 = python3Packages.callPackage ../llm-claude-3 { };

  pyWithLlm = (
    pkgs.python3.withPackages (_: [
      llm
      llm-claude-3
    ])
  );
in
pkgs.writeShellScriptBin "llm" ''
  exec ${pyWithLlm}/bin/llm "$@"
''
