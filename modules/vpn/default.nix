{
  config,
  pkgs,
  mkOizysModule,
  ...
}:

mkOizysModule config "vpn" {
  environment.systemPackages = with pkgs; [

    openconnect
    openvpn
  ];
  services.openvpn.servers = {

    mullvad-us-atl = {
      config = ''
        config ${./mullvad_us_atl.conf}
        auth-user-pass ${config.sops.secrets.mullvad-userpass.path}
        ca ${config.sops.secrets."mullvad_ca.crt".path}
      '';

      autoStart = false;
      updateResolvConf = true;
    };
  };
}
