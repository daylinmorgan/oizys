{
  pkgs,
  ...
}:
let
  inherit (pkgs) python3Packages;
  llm = python3Packages.callPackage ../llm { };
  plugins = [
    "anthropic"
    "gemini"
    "cmd"
    "jq"
  ];

  pluginPackages = plugins |> map (name: python3Packages.callPackage (../. + "/llm-${name}") { });

  pyWithLlm = (
    pkgs.python3.withPackages (
      _:
      [
        llm
      ]
      ++ pluginPackages
    )
  );
in
pkgs.writeShellScriptBin "llm" ''
  exec ${pyWithLlm}/bin/llm "$@"
''
