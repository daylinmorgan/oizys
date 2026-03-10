{
  caddy,
}:
caddy.overrideAttrs (
  finalAttrs: prevAttrs: {
    name = "caddy-with-plugins";
    version = "2.11.2";
    src = ./.;
    vendorHash = "sha256-XzxMVlxOPRqyjXz4lI6Pw+th78OOCpmYSvbO83gyu9E=";
  }
)
