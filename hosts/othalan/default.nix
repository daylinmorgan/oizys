{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    desktop
    hyprland

    nix-ld
    virtualization

    restic
  ];

  services.vpn.enable = true;

  languages = {
    misc.enable = true;
    python.enable = true;
    nim.enable = true;
    tex.enable = true;
    node.enable = true;
  };


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

  programs.zsh.enable = true;
  users.users.daylin = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel" # sudo
      "video" # backlight control via light
      "audio"
    ];
  };
}
