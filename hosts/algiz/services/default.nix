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
    ./gotosocial
    ./pds
    ./yamtrack
  ];

  services = {
    resolved = enabled;

    fail2ban = enabled // {
      maxretry = 5;
      bantime = "24h";
      bantime-increment = enabled // {
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h"; # Do not ban for more than 1 week
        overalljails = true; # Calculate the bantime based on all the violations
      };
    };

    openssh = enabled // {
      settings.PasswordAuthentication = false;
    };
  };
}
