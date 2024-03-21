{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.oizys.desktop.enable {
    environment.systemPackages = with pkgs; [
      # vscode
      vscode-fhs
    ];
  };
}
