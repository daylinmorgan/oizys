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
    # subscription expired
    # express-ny = {
    #   config = ''
    #     config /home/daylin/.config/openvpn/express-ny/config.ovpn
    #     auth-user-pass /home/daylin/.config/openvpn/express-ny/credentials
    #   '';
    #   autoStart = false;
    #   updateResolvConf = true;
    # };
    #
  
    mullvad-chi = {
      config = ''
        config /home/daylin/.config/openvpn/mullvad-chi/mullvad_us_chi.conf
      '';
      autoStart = false;
      updateResolvConf = true;
    };
  };

}
