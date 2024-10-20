{ pkgs, ... }:
{
  nph = pkgs.callPackage ./nim/nph { }; # doesn't compile with 2.2.0 :/
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  nimble = pkgs.callPackage ./nim/nimble { };
  distrobox = pkgs.callPackage ./distrobox {};
}
