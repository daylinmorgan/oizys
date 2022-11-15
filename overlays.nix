{ lib, config, pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super:
      {
        wavebox = super.wavebox.overrideAttrs
          (old: {
            version = "10.107.10";
            src = super.fetchurl {
              url = "https://download.wavebox.app/stable/linux/tar/Wavebox_10.107.10-2.tar.gz";
              sha256 = "sha256-cbcAmnq9rJlQy6Y+06G647R72HWcK97KgSsYgusSB58=";
            };
            nativeBuildInputs = with pkgs; [
              autoPatchelfHook
              makeWrapper
              qt5.wrapQtAppsHook
            ];
            buildInputs = with pkgs.xorg; [
              libXdmcp
              libXScrnSaver
              libXtst
              libXdamage
            ] ++
            (with pkgs; [
              alsa-lib
              gtk3
              nss
              mesa
            ]);
            postFixup = ''
              # make xdg-open overrideable at runtime
              makeWrapper $out/opt/wavebox/wavebox $out/bin/wavebox \
                --suffix PATH : ${super.xdg-utils}/bin
            '';
          });

        picom = super.picom.overrideAttrs (o: {
          src = pkgs.fetchFromGitHub {
            repo = "picom";
            owner = "ibhagwan";
            rev = "44b4970f70d6b23759a61a2b94d9bfb4351b41b1";
            sha256 = "0iff4bwpc00xbjad0m000midslgx12aihs33mdvfckr75r114ylh";
          };
        });
      })
  ];



}
