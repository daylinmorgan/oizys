{
  pkgs,
  enabled,
  flake,
  ...
}:
let
  static-nix-cache = pkgs.runCommandLocal "static-files-nix-cache" { } ''
    mkdir $out
    cp -r ${./nix-cache}/* $out
  '';
in
{

  services.caddy = enabled // {
    package = pkgs.caddy.withPlugins {
      plugins = [ "pkg.jsn.cam/caddy-defender@v0.9.0" ];
      hash = "sha256-BcaPGwhJ+e9th+tlpqK7iyGwVedwJNgtcEBSqPvUM9I=";
    };
    logFormat = ''
      output file /var/log/caddy/access.log
    '';

    extraConfig = builtins.readFile ./Caddyfile;

    virtualHosts = {
      "dayl.in".extraConfig = ''

        handle /* {
          root * ${flake.pkg "daylin-website"}
          encode zstd gzip
          file_server
        }

        handle /.well-known/matrix/* {
          # matrix well-known
          reverse_proxy http://localhost:8448
        }

        handle_errors 404 {
          rewrite * /{err.status_code}.html
          file_server
        }

        handle_errors {
        	respond "{err.status_code} {err.status_text}"
        }
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
          reverse_proxy http://localhost:5656
        }
      '';
    };
  };
}
