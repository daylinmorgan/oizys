{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkOizysModule;
in
  mkOizysModule config "docker" {
    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      lazydocker
    ];
  }
# in {
#   options.oizys.docker.enable = mkEnableOption "enable docker support";
#
#   config = mkIf cfg.enable {
#     virtualisation.docker.enable = true;
#     environment.systemPackages = with pkgs; [
#       lazydocker
#     ];
#   };
# }

