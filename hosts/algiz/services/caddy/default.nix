{
  enabled,
  flake,
  ...
}:
{

  services.caddy = enabled // {
    package = (flake.pkgs "self").caddy-with-plugins;

    logFormat = ''
      output file /var/log/caddy/access.log
    '';

    extraConfig = builtins.readFile ./Caddyfile;
  };
}
