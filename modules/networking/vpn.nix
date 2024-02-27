{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.oizys.vpn;
in {
  options.oizys.vpn.enable = mkEnableOption ''
    Whether to enable openconnect for vpn connection.
  '';

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.openconnect];
  };
}
