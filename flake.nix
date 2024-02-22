{
  description = "nix begat oizys";
  inputs.inputs.url = "github:daylinmorgan/oizys?dir=inputs";
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
