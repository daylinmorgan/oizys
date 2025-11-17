{
  enabled,
  pkgs,
  ...
}:
{
  oizys = {
    rune.motd = enabled;
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "gitea" ''
      ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    '')
  ];

  # git user handles the forgjo ssh authentication
  users.users.git.isNormalUser = true;


  networking.extraHosts = ''
    127.0.0.1 nix-cache.dayl.in
  '';

  # allow tcp connections for reverse proxy
  networking.firewall = enabled // {
    allowedTCPPorts = [
      80
      443
    ];
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub = enabled // {
    device = "/dev/sda"; # or "nodev" for efi only
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
