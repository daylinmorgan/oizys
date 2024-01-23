{...}: (final: prev: {
  wezterm = prev.wezterm.overrideAttrs {
    src = prev.fetchFromGitHub {
      version = "main-20240121";
      owner = "wez";
      repo = "wezterm";
      rev = "b0671294d1c9225096909e12875ada25dd19a35e";
      hash = "sha256-oIt4bUVXRR7qnBPizcPA7fTiZl4xz9QaSdzLNukjtkw=";
    };
  };
})
