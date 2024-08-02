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
    express-ny = {
      config = ''
        config /home/${config.oizys.user}/.config/openvpn/express-ny/config.ovpn
        auth-user-pass /home/${config.oizys.user}/.config/openvpn/express-ny/credentials
      '';
      autoStart = false;
      updateResolvConf = true;
    };
  };
}
