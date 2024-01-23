{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    inputs.wezterm.packages.${pkgs.system}.default
    alacritty

    inkscape
    gimp

    libreoffice-qt
    hunspell # spell check for libreoffice

    (vivaldi.override {
      commandLineArgs = [
        "--force-dark-mode"
      ];
      proprietaryCodecs = true;
    })
  ];
}
