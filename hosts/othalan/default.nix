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
    docker
  ];

  oizys = {
    languages = [
      "misc"
      "python"
      "nim"
      "tex"
      "node"
    ];
    nix-ld = enabled;
    vbox = enabled;
    desktop = enabled;
    vpn = enabled;
    chrome = enabled;
  };

  environment.systemPackages = with pkgs; [
    zk
    rclone
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
