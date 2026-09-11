{ enabled, config, ... }:
{
  sops.secrets.miniflux = { };
  services.miniflux = enabled // {
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config.LISTEN_ADDR = "localhost:8055";
  };
}
