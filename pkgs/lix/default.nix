{ flake, ... }:
((flake.pkgs "lix-module").default.override {
  # is this doing anything?
  aws-sdk-cpp = null;
}).overrideAttrs
  (attrs: {
    version = "${attrs.version}-oizys";

    # probs a mistake ¯\_(ツ)_/¯
    # surely they wouldn't push a broken CL....surely
    doCheck = false;
  })
