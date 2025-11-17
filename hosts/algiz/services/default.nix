{
  enabled,
  ...
}:
{

  imports = [
    ./caddy
    ./otterwiki
    ./linkding
    ./nix-cache
  ];

  services = {
    resolved = enabled;

    fail2ban = enabled // {
      maxretry = 5;
      bantime = "24h";
    };

    openssh = enabled // {
      settings.PasswordAuthentication = false;
    };
  };
}
