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
    ./forgejo
    ./dayl.in
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
