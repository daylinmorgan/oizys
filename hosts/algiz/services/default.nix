{
  enabled,
  ...
}:
{

  imports = [
    ./caddy
    ./nix-cache
    ./continuwuity
    ./linkding
    ./otterwiki
    ./soft-serve
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
