{...}: (final: prev: {
  nim-unwrapped-2 = prev.nim-unwrapped-2.overrideAttrs {
    patches =
      (prev.patches or [])
      ++ [
        ./install.patch
      ];
    # installPhase = ''
    #   runHook preInstall
    #   install -Dt $out/bin bin/*
    #   ln -sf $out/nim/bin/nim $out/bin/nim
    #   ln -sf $out/nim/lib $out/lib
    #   ./install.sh $out
    #   cp -a dist tools $out/nim/
    #   runHook postInstall
    # '';
  };
})
