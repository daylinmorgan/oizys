{
  self,
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    types
    mkMerge
    mkOption
    mkIf
    mkEnableOption
    ;
  runes = {
    othalan = import ./othalan.nix;
    algiz = import ./algiz.nix;
    mannaz = import ./mannaz.nix;
    naudiz = import ./naudiz.nix;
  };
  mkRune =
    {
      name,
      number ? "6",
      kind ? "braille",
    }:
    "[1;3${number}m\n" + runes.${name}.${kind} + "\n[0m";

  cfg = config.oizys.rune;

  # TODO: include time? things would be simpler with epoch and printf/date
  dateFromFlake =
    flake:
    flake.lastModifiedDate |> builtins.match "(.{4})(.{2})(.{2}).*" |> builtins.concatStringsSep "-";
  nixpkgsDate = dateFromFlake inputs.nixpkgs;
  oizysDate = dateFromFlake self;
  mkMotd =
    rune:
    rune
    + ''
      nixpkgs:
        last modified: ${nixpkgsDate}
        rev: ${inputs.nixpkgs.rev}
      oizys:
        last modified: ${oizysDate}
        rev: ${self.rev or "dirty"}
    '';

in
{
  options.oizys = {
    rune = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      motd.enable = mkEnableOption "set rune for MOTD";
      name = mkOption {
        default = config.networking.hostName;
        type = types.either (types.enum (builtins.attrNames runes)) types.str;
        description = "Name of rune (probabaly matches hostname)";
      };
      kind = mkOption {
        type =
          with types;
          either (enum [
            "ascii"
            "braille"
          ]) str;
        default = "ascii";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.etc.issue = {
        source = pkgs.writeText "issue" (
          {
            name = cfg.name;
            kind = cfg.kind;
          }
          |> mkRune
          |> mkMotd
        );
      };
    })
    (mkIf cfg.motd.enable {
      users.motd =
        {
          number = "2"; # todo: autogenerate based on hostname?
          name = cfg.name;
        }
        |> mkRune
        |> mkMotd;
    })
  ];
}
