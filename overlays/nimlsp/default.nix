{...}: (final: prev: {
  nimlsp = prev.nimlsp.overrideNimAttrs {
    requiredNimVersion = 2;
    nimFlags = [
      "--threads:on"
      ""
      "-d:explicitSourcePath=${final.srcOnly final.pkgs.nim-unwrapped-2}"
      "-d:tempDir=/tmp"
    ];
  };
})
