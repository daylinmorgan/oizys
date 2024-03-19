{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.oizys.docker;
in {
  options.oizys.docker.enable = mkEnableOption "enable docker support";

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      lazydocker
    ];
  };
}
