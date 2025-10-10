{
  config,
  pkgs,
  enabled,
  ...
}:
let
  check-attic = pkgs.writeShellScriptBin "check-attic" ''
    sudo du -sh /var/lib/atticd/
  '';
in
{
  environment.systemPackages = [
    pkgs.attic-client
    check-attic
  ];

  security.polkit = enabled; # attic was looking for this...

  services = {
    resolved = enabled;

    fail2ban = enabled // {
      maxretry = 5;
      bantime = "24h";
    };

    openssh = enabled // {
      settings.PasswordAuthentication = false;
    };

    atticd = enabled // {

      # Replace with absolute path to your credentials file
      environmentFile = config.sops.secrets."atticd-env".path;

      # https://github.com/zhaofengli/attic/blob/main/server/src/config.rs
      # best of luck to you converting this to nix, which is written by nix as toml to be read by attic
      settings = {
        listen = "[::]:5656";

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
  };
}
