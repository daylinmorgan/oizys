{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.desktop;
in {
  config = mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
    # vscode
    vscode-fhs
  ];
};
}
