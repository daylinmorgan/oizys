{
  pkgs,
  self,
  lib,
  ...
}: let
  inherit (lib) enableAttrs;
in {
  imports = with self.nixosModules; [
    restic
  ];

  oizys =
    {
      languages = [
        "misc"
        "python"
        "nim"
        "tex"
        "node"
      ];
    }
    // enableAttrs [
      "chrome"
      "desktop"
      "docker"
      "nix-ld"
      "vbox"
      "vpn"
    ];

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
