{ pkgs, ... }:
{
  nph = pkgs.callPackage ./nim/nph { };
  nimlangserver = pkgs.callPackage ./nim/nimlangserver { };
  nimble = pkgs.callPackage ./nim/nimble { };
}
