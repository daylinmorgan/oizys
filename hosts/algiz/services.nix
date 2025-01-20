{
  pkgs,
  enabled,
  flake,
  ...
}:
let
  atticPort = "5656";
  static = pkgs.runCommandLocal "static-files" { } ''
    mkdir $out
    cp ${./caddy/index.html} $out/index.html
  '';
in
{

  services.resolved = enabled;

  services.fail2ban = enabled // {
    maxretry = 5;
    bantime = "24h";
  };

  services.openssh = enabled // {
    settings.PasswordAuthentication = false;
  };

  security.polkit = enabled; # attic was looking for this...
  environment.systemPackages = [ (flake.pkgs "self").attic-client ];

  # allow docker to forward the request to the host running attic
  # https://discourse.nixos.org/t/docker-container-not-resolving-to-host/30259/6
  # networking.firewall.extraCommands = "iptables -A INPUT -p tcp --destination-port ${atticPort} -s 172.16.0.0/12 -j ACCEPT";
  services.atticd = enabled // {
    package = (flake.pkgs "self").attic-server;

    # Replace with absolute path to your credentials file
    # TODO: replace with sops-secret!
    environmentFile = "/etc/atticd.env";

    settings = {
      listen = "[::]:${atticPort}";

      jwt = { };

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 16 * 1024; # 16 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 64 * 1024; # 64 KiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };

  services.caddy = enabled // {
    extraConfig = builtins.readFile ./caddy/Caddyfile;
    virtualHosts."attic.dayl.in".extraConfig = ''
      redir /oizys /

      handle / {
        root * ${static}
        file_server
      }

      handle /* {
        reverse_proxy http://localhost:5656
      }
    '';
  };
}
