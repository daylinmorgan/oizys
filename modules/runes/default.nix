{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    mkEnableOption
    ;
  runes = {
    othalan = import ./othalan.nix;
    algiz = import ./algiz.nix;
    mannaz = import ./mannaz.nix;
  };
  mkRune =
    {
      rune,
      number ? "6",
      runeKind ? "braille",
    }:
    "[1;3${number}m\n" + runes.${rune}.${runeKind} + "\n[0m";
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

  config =
    mkIf cfg.enable {
      environment.etc.issue = {
        source = pkgs.writeText "issue" (mkRune {
          rune = cfg.name;
          runeKind = cfg.kind;
        });
      };
    }
    // mkIf cfg.motd.enable {
      users.motd = mkRune {
        number = "2"; # todo: autogenerate based on hostname?
        rune = cfg.name;
      };
    };
}
