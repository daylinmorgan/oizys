{
  pkgs,
  ...
}:
let
  inherit (builtins) mapAttrs attrValues;
  inherit (pkgs) python3Packages;
  mkPlugin = name: attrs: python3Packages.callPackage (import (../. + "/llm-${name}") attrs) { };

  llm = python3Packages.callPackage ../llm { };

  pluginAttr = {
    anthropic = {
      version = "0.13";
      hash = "sha256-eIppCyFu/2VKExkO88iRozC9AVDcRQaUKrNeLU89rrQ=";
    };
    gemini = {
      version = "0.11";
      hash = "sha256-xYtfIajEU1iqHvSPDLmg9lHEllcKpVYyUuNZUGNcccw=";
    };
    cmd = {
      version = "0.2a0";
      hash = "sha256-RhwQEllpee/XP1p0nrgL4m+KjSZzf61J8l1jJGlg94E=";
    };
    jq = {
      version = "0.1.1";
      hash = "sha256-Mf/tbB9+UdmSRpulqv5Wagr8wjDcRrNs2741DNQZhO4=";
    };
    python = {
      version = "0.1";
      hash = "sha256-Z991f0AGO5iaCeoG9dkFhTLtuR45PgCS9awCvOAuPPs=";
    };
  };

  pluginPackages = pluginAttr |> mapAttrs mkPlugin |> attrValues;
  pyWithLlm = (pkgs.python3.withPackages (_: [ llm ] ++ pluginPackages));

in
pkgs.writeShellScriptBin "llm" ''
  exec ${pyWithLlm}/bin/llm "$@"
''
