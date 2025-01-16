{ pkgs, ... }:
{
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  procs = pkgs.callPackage ./nim/procs { };
  nimble = pkgs.callPackage ./nim/nimble { };

  distrobox = pkgs.callPackage ./distrobox { };

  llm-with-plugins = pkgs.callPackage ./llm/llm-with-plugins { };
}
