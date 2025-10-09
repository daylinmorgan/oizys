{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.oizys.desktop.enable {
    fonts.fontconfig.enable = true;
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      recursive
      maple-mono.NF # nice monolisa alternative if needed
    ];
  };
}
