{
  inputs,
  config,
  lib,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    fonts
    gui
    vscode
    hyprland
  ];
}
