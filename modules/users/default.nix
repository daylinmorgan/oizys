{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.users.defaultUser;
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
        "wheel" # sudo
        "docker"
      ];
      initialHashedPassword = "$2b$05$mGMrDFzf2cXLaoOlVQbGvOBV7UZlDt9dLg9Xqxutb/uHpjF5VrTBO";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkezPIhB+QW37G15ZV3bewydpyEcNlYxfHLlzuk3PH9"
      ];
    };
  };
}
