{
  pkgs,
  config,
  enabled,
  mkOizysModule,
  ...
}:
mkOizysModule config "plasma" {

  services = {
    displayManager.sddm = enabled // {
      wayland = enabled;
    };
    desktopManager.plasma6 = enabled;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    (lib.getBin qttools) # Expose qdbus in PATH
    ark
    elisa
    gwenview
    okular
    kate
    khelpcenter
    dolphin
    baloo-widgets # baloo information in Dolphin
    dolphin-plugins
    spectacle
    ffmpegthumbs
    krdp
    # xwaylandvideobridge # exposes Wayland windows to X11 screen capture
  ];
}
