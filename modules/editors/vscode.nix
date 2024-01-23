{
  input,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # vscode
    vscode-fhs
  ];
}
