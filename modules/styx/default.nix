{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    (writeScriptBin "styx" (builtins.readFile ./styx))
  ];
}
