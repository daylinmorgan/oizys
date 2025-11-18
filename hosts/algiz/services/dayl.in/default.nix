{
  flake,
  ...
}:
{
  services.caddy.virtualHosts."dayl.in".extraConfig = ''
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
}
