{ lib, config, pkgs, ... }:

{
  # for compatibility add zsh to list of /etc/shells
  environment.shells = with pkgs; [ zsh ];

  environment.etc = {
    issue.source = ../etc/issue;
  };

  environment.variables = {
    NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
      stdenv.cc.cc
      openssl

      zlib # for delta
    ];
    NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  };

}
