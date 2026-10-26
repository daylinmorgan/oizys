{
  lib,
  caddy,
}:
let
  # use the caddy version pinned in go.mod rather than nixpkgs'
  version = lib.pipe ./go.mod [
    builtins.readFile
    (lib.splitString "\n")
    (map (builtins.match "[[:space:]]*github.com/caddyserver/caddy/v2 v([^[:space:]]+).*"))
    (lib.findFirst (m: m != null) (throw "caddy version not found in go.mod"))
    builtins.head
  ];
in
lib.warnIf (version != caddy.version)
  "caddy-with-plugins: go.mod pins caddy ${version} but nixpkgs has ${caddy.version}"
  caddy.overrideAttrs
  (
  finalAttrs: prevAttrs: {
    inherit version;
    pname = "caddy-with-plugins";
    src = ./.;

    # https://github.com/NixOS/nixpkgs/blob/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504/pkgs/by-name/ca/caddy/package.nix#L52-L57
    postConfigure = ''
      # vendor/ is copied from the read-only goModules store path
      chmod u+w vendor/github.com/caddyserver/caddy/v2/cmd
      rm vendor/github.com/caddyserver/caddy/v2/cmd/x509rootsfallback.go
    '';

    vendorHash = "sha256-LfvcVmMtFXN9wHEmPd+C+/8rUsLHbQakZNH2m4V0zXg=";
  }
)
