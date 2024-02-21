{
  description = "nix begat oizys";
  # inputs.flake-inputs.url = "github:daylinmorgan/oizys?dir=inputs";
  inputs.inputs.url = "path:./inputs";
  outputs = {
    inputs,
    self,
  }:
    (import ./lib {
      inherit (inputs) inputs;
      inherit self;
    })
    .oizysFlake {};
}
