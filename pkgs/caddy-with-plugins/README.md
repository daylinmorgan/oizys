# Caddy with my plugins

Due to an [issue](https://github.com/NixOS/nixpkgs/issues/450289) with how the caddy with plugins is implemented,
even if the plugins don't change the underlying hash will since it generates a go.mod on demand with xcaddy.
Instead, I'll manually build caddy with plugins so that I don't need to update a hash at random.

Original caddy package was defined like this

```nix
pkgs.caddy.withPlugins {
  plugins = [ "pkg.jsn.cam/caddy-defender@v0.9.0" ];
  hash = "<hash>";
}
```
