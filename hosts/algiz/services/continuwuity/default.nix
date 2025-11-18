{ config, ... }:
{
  environment.etc."containers/systemd/continuwuity.container".text = ''
    [Unit]
    Description=continuwuity

    [Container]
    Image=forgejo.ellis.link/continuwuation/continuwuity:v0.5.0-rc.8.1
    Volume=/opt/continuwuity/data/:/var/lib/continuwuity:Z,U
    EnvironmentFile=${config.sops.secrets."continuwuity-env".path}
    PublishPort=8448:6167

    [Service]
    # Restart service when sleep finishes
    Restart=always

    [Install]
    WantedBy=multi-user.target
  '';
}
