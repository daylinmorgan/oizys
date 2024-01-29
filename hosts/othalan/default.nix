{
  inputs,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    nix-ld
    virtualbox
    restic
  ];

  cli.enable = true;
  desktop.enable = true;

  languages = {
    misc = true;
    python = true;
    nim = true;
    tex = true;
    node = true;
  };
  environment.systemPackages = with pkgs; [
    zk
    rclone
    quarto
  ];

  programs.hyprland.enable = true;

  services.vpn.enable = true;

  services.restic.backups.gdrive = {
    user = "daylin";
    repository = "rclone:g:archives/othalan";
    passwordFile = "/home/daylin/.config/restic/othalan-pass";
    paths = ["/home/daylin/stuff/" "/home/daylin/dev/"];
  };

  users.users.daylin.extraGroups = [
    "audio"
  ];
}
