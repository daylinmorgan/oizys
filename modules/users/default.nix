{
  nixpkgs,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.users.defaultUser;
in {
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
    ];
    initialPassword = "nix";
  };
  };
}
