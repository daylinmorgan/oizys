treefmt-nix: pkgs:
(treefmt-nix.lib.evalModule pkgs (
  { ... }:
  {
    projectRootFile = "flake.nix";
    # don't warn me about missing formatters
    settings.excludes = [
      # likely to be nnl lockfiles
      "pkgs/**/lock.json"
      "hosts/**/secrets.yaml"
    ];
    settings.on-unmatched = "debug";
    programs.prettier.enable = true;
    programs.nixfmt.enable = true;
  }
))
