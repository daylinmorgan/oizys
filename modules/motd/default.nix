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
    {
      img,
      color,
      figName,
    }:
    (
      "[1;${toString color}m"
      + (readFile img)
      + (readFile figName)
      + "[0m"
      + ''
        nixpkgs:
          last modified: ${nixpkgsDate}
          rev: ${inputs.nixpkgs.rev}
        oizys:
          last modified: ${oizysDate}
          rev: ${self.rev or "dirty"}
      ''
    );
  mkMotdText =
    { color, figName }:
    mkText {
      img = motdPath;
      inherit color figName;
    };
  mkIssueText =
    { color, figName }:
    mkText {
      img = issuePath;
      inherit color figName;
    }
    # prevent agetty from messing up the name
    |> lib.stringAsChars (x: if x == "\\" then "\\\\" else x);
  cfg = config.oizys.motd;
in
{
  options.oizys = {
    motd = {
      color = mkOption {
        type = types.int;
        default = 36;
      };
      font = mkOption {
        type = types.str;
        default = "larry3d";
      };
    };
  };

  config =
    let
      figName = pkgs.runCommandLocal "figlet-${config.networking.hostName}-${cfg.font}" { } ''
        ${pkgs.figlet}/bin/figlet ${config.networking.hostName} -f ${cfg.font} > $out
      '';
    in
    mkMerge [
      (mkIf (pathExists issuePath) {
        environment.etc.issue = {
          text = mkIssueText {
            inherit (cfg) color;
            inherit figName;
          };
        };
      })
      (mkIf (pathExists motdPath) {
        users.motd = mkMotdText {
          inherit (cfg) color;
          inherit figName;
        };
      })
    ];
}
