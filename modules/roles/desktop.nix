{
  inputs,
  config,
  lib,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    common
    gui
    vscode
    vpn
    # qtile
  ];
}
