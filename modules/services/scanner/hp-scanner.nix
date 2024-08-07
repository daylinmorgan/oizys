{
  enabled,
  config,
  pkgs,
  mkOizysModule,
  ...
}:
mkOizysModule config "hp-scanner" {

  environment.systemPackages = [ pkgs.kdePackages.skanpage ];

  hardware.sane = enabled // {
    extraBackends = [ pkgs.hplipWithPlugin ];
  };

  services.avahi = enabled // {
    nssmdns4 = true;
  };

  users.users.${config.oizys.user}.extraGroups = [
    "scanner"
    "lp"
  ];

}
