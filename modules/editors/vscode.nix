{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
# TODO: explore the ability to expand this so that some of the worthwile extensions are also included.
# I don't think it will be simple to integrate vscode-fhs and vscode-with-extensions
{
  config = mkIf config.oizys.desktop.enable {
    environment.systemPackages = with pkgs; [
      # vscode
      vscode-fhs
    ];
  };
}
