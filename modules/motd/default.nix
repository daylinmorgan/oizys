{
  inputs,
  self,
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (builtins) pathExists readFile;
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  issuePath = ../../hosts/${config.networking.hostName}/settings/issue;
  motdPath = ../../hosts/${config.networking.hostName}/settings/motd;
  figName = pkgs.runCommandLocal "figlet-hostname" { } ''
    ${pkgs.figlet}/bin/figlet ${config.networking.hostName} -f larry3d > $out
  '';

  # TODO: include time? things would be simpler with epoch and printf/date
  dateFromFlake =
    flake:
    flake.lastModifiedDate |> builtins.match "(.{4})(.{2})(.{2}).*" |> builtins.concatStringsSep "-";
  nixpkgsDate = dateFromFlake inputs.nixpkgs;
  oizysDate = dateFromFlake self;

  mkText =
    img:
    color:
    (
      "[1;36m"
      + (readFile img)
      + (readFile figName)
      + "[0m" + ''
        nixpkgs:
          last modified: ${nixpkgsDate}
          rev: ${inputs.nixpkgs.rev}
        oizys:
          last modified: ${oizysDate}
          rev: ${self.rev or "dirty"}
      ''
    );
  mkMotdText = color: mkText motdPath color;
  mkIssueText = color: mkText issuePath color;

in
{
  options.oizys = {
    motd = {
      color = mkOption {
        type = types.int;
        default = 6;
      };
    };
  };

  config = mkMerge [
    (mkIf (pathExists issuePath) {
      # oizys.rune.issue.enable = false;
      environment.etc.issue = {
        text = mkIssueText config.oizys.motd.color;
      };
    })
    (mkIf (pathExists motdPath) {
      # oizys.rune.motd.enable = false;
      users.motd = mkMotdText config.oizys.motd.color;
    })
  ];
}
