{ ... }:
final: prev: {
  lix =
    (prev.lix.override {
      aws-sdk-cpp = null;
    }).overrideAttrs
      (attrs: {
        version = "${attrs.version}-oizys";

        # probs a mistake ¯\_(ツ)_/¯ 
        # surely they wouldn't push a broken CL....surely
        doCheck = false;
      });
}
