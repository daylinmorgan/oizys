{ ... }:
{
  environment.etc."containers/systemd/gotosocial.container" = {
    text = ''
      [Unit]
      Description=gotosocial

      [Container]
      Image=docker.io/superseriousbusiness/gotosocial:0.19.1
      Volume=/opt/gotosocial/fonts:/gotosocial/web/assets/myfonts/:Z,U
      Volume=/opt/gotosocial/data:/gotosocial/storage:Z,U
      PublishPort=3758:3758
      EnvironmentFile=${./env}

      [Service]
      # Restart service when sleep finishes
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
