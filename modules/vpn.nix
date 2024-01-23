{config, lib,pkgs,...}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.services.vpn;
in {
  options.services.vpn.enable = mkEnableOption ''
    use openconnect vpn
  '';

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.openconnect];
  };
}
