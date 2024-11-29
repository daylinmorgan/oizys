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

    mullvad-chi = {
      config = ''
        config ${./mullvad_us_chi.conf}
        auth-user-pass ${config.sops.secrets.mullvad-userpass.path}
        ca ${config.sops.secrets."mullvad_ca.crt".path}
      '';

      autoStart = false;
      updateResolvConf = true;
    };
  };
}
