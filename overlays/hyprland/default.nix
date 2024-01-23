{...}: (final: prev: {
  hyprland = prev.hyprland.overrideAttrs {
    src = prev.fetchFromGitHub {
      version = "main-20240121";
      owner = "hyprwm";
      repo = "Hyprland";
      rev = "3c964a9fdc220250a85b1c498e5b6fad9390272f";
      hash = "sha256-oIt4bUVXRR7qnBPizcPA7fTiZl4xz9QaSdzLNukjtkw=";
    };
  };
})
