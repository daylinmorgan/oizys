{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.oizys.languages;
in {
  config = mkIf (builtins.elem "node" cfg) {
    environment.systemPackages = with pkgs; [
      nodejs
      nodePackages.pnpm
    ];
  };
}
