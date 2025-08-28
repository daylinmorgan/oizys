{
  config,
  pkgs,
  enabled,
  flake,
  ...
}:
let
  atticPort = "5656";
  static-nix-cache = pkgs.runCommandLocal "static-files-nix-cache" { } ''
    mkdir $out
    cp -r ${./caddy/nix-cache}/* $out
  '';

  check-attic = pkgs.writeShellScriptBin "check-attic" ''
    sudo du -sh /var/lib/atticd/
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

  environment.systemPackages = [
    pkgs.attic-client
    check-attic
  ];

  services.atticd = enabled // {

    # Replace with absolute path to your credentials file
    environmentFile = config.sops.secrets."atticd-env".path;

    # https://github.com/zhaofengli/attic/blob/main/server/src/config.rs
    # best of luck to you converting this to nix, which is written by nix as toml to be read by attic
    settings = {
      listen = "[::]:${atticPort}";

      jwt = { };

      garbage-collection = {
        interval = "1 day";
        retention-period = "2 weeks";
      };

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
    logFormat = ''
      output file /var/log/caddy/access.log
    '';

    extraConfig = builtins.readFile ./caddy/Caddyfile;

    virtualHosts = {

      "https://cloud.dayl.in:443".extraConfig = ''
        # reverse_proxy localhost:11000
        respond "No service active"
      '';

      "www.dayl.in".extraConfig = ''
        redir https://dayl.in{uri}
      '';

      "dayl.in".extraConfig = ''
        root * ${flake.pkg "daylin-website"}
        encode zstd gzip
        file_server
      '';

      "nix-cache.dayl.in".extraConfig = ''

        redir /oizys /

        @frontend {
          path /
          path /daylin-nix-cache-logo.svg
        }

        handle @frontend {
          root * ${static-nix-cache}
          file_server
        }

        handle /* {
          reverse_proxy http://localhost:${atticPort}
        }
      '';
    };
  };
}
