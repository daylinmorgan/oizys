{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # language supports
    nodejs
    go
    rustup
  ];
}
