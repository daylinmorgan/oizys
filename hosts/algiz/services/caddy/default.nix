{
  pkgs,
  enabled,
  ...
}:
{

  services.caddy = enabled // {
    package = pkgs.caddy.withPlugins {
      plugins = [ "pkg.jsn.cam/caddy-defender@v0.9.0" ];
      hash = "sha256-BcaPGwhJ+e9th+tlpqK7iyGwVedwJNgtcEBSqPvUM9I=";
    };
    logFormat = ''
      output file /var/log/caddy/access.log
    '';

    extraConfig = builtins.readFile ./Caddyfile;
 };
}
