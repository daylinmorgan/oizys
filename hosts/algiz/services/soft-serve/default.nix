{ ... }:
let

  inherit (import ../images.nix  ) soft-serve;
in
{
  environment.etc."containers/systemd/soft-serve.container".text = ''
    [Unit]
    Description=soft-serve

    [Container]
    Image=${soft-serve}
    # make sure git zombie processes don't bog us down
    RunInit=true
    Volume=/var/lib/soft-serve/data:/soft-serve
    PublishPort=23231:23231
    PublishPort=23232:23232
    PublishPort=23233:23233
    PublishPort=9418:9418

    [Service]
    # Restart service when sleep finishes
    Restart=always

    [Install]
    WantedBy=multi-user.target
  '';
}
