{
  description = "nix begat oizys";

  # inputs.flake-inputs.url = "github:daylinmorgan/oizys?dir=inputs";
  inputs.flake-inputs.url = "path:./inputs";

  outputs = {
    self,
    flake-inputs,
  }:
    (import ./lib {
      inherit self;
      inputs = flake-inputs.inputs;
    })
    .oizysFlake {};
}
