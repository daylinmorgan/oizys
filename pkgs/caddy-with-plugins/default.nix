{
  caddy,
}:
caddy.overrideAttrs (
  finalAttrs: prevAttrs: {
    name = "caddy-with-plugins";
    version = "2.10.2";
    src = ./.;
    vendorHash = "sha256-fArwOEan5FtuIXdEDn/QVduKKFQBmREWECl2iHrkukE=";
  }
)
