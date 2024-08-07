{
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
        source = pkgs.writeText "issue" (mkRune {
          name = cfg.name;
          kind = cfg.kind;
        });
      };
    })
    (mkIf cfg.motd.enable {
      users.motd = mkRune {
        number = "2"; # todo: autogenerate based on hostname?
        name = cfg.name;
      };
    })
  ];
}
