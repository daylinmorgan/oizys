{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    desktop
    #  hyprland

    nix-ld
    virtualbox
    restic
  ];
  programs.hyprland.enable = true;

  services.vpn.enable = true;

  languages = {
    misc = true;
    python = true;
    nim = true;
    tex = true;
    node = true;
  };
  cli.enable = true;

  services.restic.backups.gdrive = {
    user = "daylin";
    repository = "rclone:g:archives/othalan";
    passwordFile = "/home/daylin/.config/restic/othalan-pass";
    paths = ["/home/daylin/stuff/" "/home/daylin/dev/"];
  };

  environment.systemPackages = with pkgs; [
    zk
    rclone
    quarto
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  users.users.daylin.extraGroups = [
      "video" # backlight control via light
      "audio"
  ];

  # users.users.daylin = {
  #   isNormalUser = true;
  #   shell = pkgs.zsh;
  #   extraGroups = [
  #     "wheel" # sudo
  #     "video" # backlight control via light
  #     "audio"
  #   ];
  # };

}
