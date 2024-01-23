{
  inputs,
  config,
  lib,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    gui
    vscode
    vpn
  ];
}
