{
  pkgs,
  ...
}:
let
  inherit (builtins) mapAttrs attrValues;
  inherit (pkgs) python3Packages;
  mkPlugin = name: attrs: python3Packages.callPackage (import (../. + "/llm-${name}") attrs) { };

  llm = python3Packages.callPackage ../llm { };
  pluginVersions = import ../versions.nix;

  pluginPackages = pluginVersions |> mapAttrs mkPlugin |> attrValues;
  pyWithLlm = (pkgs.python3.withPackages (_: [ llm ] ++ pluginPackages));

in
pkgs.writeShellScriptBin "llm" ''
  exec ${pyWithLlm}/bin/llm "$@"
''
