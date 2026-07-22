{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    optional
    ;
  cfg = config.users.defaultUser;
  isDocker = config.oizys.docker.enable;
  isDesktop = config.oizys.desktop.enable;
  isPodman = config.oizys.podman.enable;
in
{
  options.users.defaultUser = mkOption {
    default = true;
    type = types.bool;
    description = ''
      include default user "daylin"
    '';
  };

  config = mkIf cfg {
    users.users.daylin = {
      isNormalUser = true;

      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
      ]
      ++ optional isDesktop "audio"
      ++ optional isDocker "docker"
      ++ optional isPodman "podman";

      initialHashedPassword = "$y$j9T$hRKQ4.yLNoMDV8m9A4sAy1$veJMlHOaxZQjvnrRdqZNfK61ZkQr2tdMuzXanau2Wg7";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkezPIhB+QW37G15ZV3bewydpyEcNlYxfHLlzuk3PH9"
      ];
    };
  };
}
