{
  lib,
  flake,
  enabled,
  ...
}:

{
  imports = [
    (flake.module "daylin-website")
  ];
  services.dayl-in = enabled;
  services.caddy.virtualHosts = {
    "dayl.in".extraConfig = lib.mkBefore ''
      handle /.well-known/matrix/* {
        # matrix well-known
        reverse_proxy http://localhost:8448
      }
    '';
  };
  services.dayl-in-under-construction = enabled // {
    domains = [
      "cloud.dayl.in"
      "links.dayl.in"
      "games.dayl.in"
      "blog.dayl.in"
    ];
  };
}
