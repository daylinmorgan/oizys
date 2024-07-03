{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.oizys.docker;
in
{
  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [ lazydocker ];
  };
}
