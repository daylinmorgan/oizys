{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.oizys.vbox;
in {
  options.oizys.vbox.enable = mkEnableOption "enable virtualbox host";

  config = mkIf cfg.enable {

    virtualisation.virtualbox = {
      host.enable = true;
    };
    users.extraGroups.vboxusers.members = ["daylin"];
  };
}
