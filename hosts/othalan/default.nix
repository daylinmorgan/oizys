{
  pkgs,
  self,
  ...
}: {
  imports = with self.nixosModules; [
    nix-ld
    restic
    docker
  ];

  oizys = {
    vbox.enable = true;
    desktop.enable = true;
    vpn.enable = true;
    languages = [
      "misc"
      "python"
      "nim"
      "tex"
      "node"
    ];
  };
  vivaldi.enable = true;

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
