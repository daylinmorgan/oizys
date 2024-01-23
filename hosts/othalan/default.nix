{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    common
    desktop
    hyprland

    nix-ld
    virtualization

    restic

    # langs
    misc
    nim
    node
    tex
  ];
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

    expect
    openconnect
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
