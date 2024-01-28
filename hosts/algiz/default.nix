{
  inputs,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    docker
  ];

  languages = {
    nim = true;
    python = true;
  };
  cli.enable = true;

  environment.systemPackages = with pkgs; [
    rclone
  ];

  # https://francis.begyn.be/blog/nixos-restic-backups
  # TODO: parameterize to use on algiz AND othalan ...
  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    user = "root";
    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = "/home/daylin/.config/restic/algiz-pass";
    paths = ["/home/daylin/services/git/" "/home/daylin/services/gotosocial/" "home/daylin/services/caddy"];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users = {
    daylin = {
      extraGroups = ["docker"];
    };
    git = {
      isNormalUser = true;
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
