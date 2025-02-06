{
  pkgs,
  ...
}:
let
  inherit (pkgs) python3Packages;
  llm = python3Packages.callPackage ../llm { };
  llm-anthropic = python3Packages.callPackage ../llm-anthropic { };
  llm-gemini = python3Packages.callPackage ../llm-gemini { };

  pyWithLlm = (
    pkgs.python3.withPackages (_: [
      llm
      llm-anthropic
      llm-gemini
    ])
  );
in
pkgs.writeShellScriptBin "llm" ''
  exec ${pyWithLlm}/bin/llm "$@"
''
