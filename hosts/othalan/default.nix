{
  pkgs,
  self,
  lib,
  ...
}: let
  inherit (lib) enabled;
in {
  imports = with self.nixosModules; [
    restic
  ];

  oizys = {
    desktop = enabled;
    chrome = enabled;
    docker = enabled;
    nix-ld = enabled;
    vbox = enabled;
    vpn = enabled;
    backups = enabled;
    languages = [
      "misc"
      "python"
      "nim"
      "tex"
      "node"
    ];
  };

  environment.systemPackages = with pkgs; [
    zk
    quarto
  ];

  programs.hyprland.enable = true;

  services.restic.backups.gdrive = {
    user = "daylin";
    repository = "rclone:g:archives/othalan";
    passwordFile = "/home/daylin/.config/restic/othalan-pass";
    paths = ["/home/daylin/stuff/" "/home/daylin/dev/"];
  };

  users.users.daylin.extraGroups = [
    "docker"
    "audio"
  ];
}
