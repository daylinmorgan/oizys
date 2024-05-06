{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in
{
  config = mkIfIn "node" cfg {
    environment.systemPackages = with pkgs; [
      nodejs
      nodePackages.pnpm
    ];
  };
}
