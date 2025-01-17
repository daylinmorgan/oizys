{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  makeWrapper,
  wget,
  installShellFiles,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "distrobox";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "89luca89";
    repo = "distrobox";
    rev = finalAttrs.version;
    hash = "sha256-e9oSTk+UlkrkRSipqjjMqwtxEvEZffVBmlSTmsIT7cU=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  installPhase = ''
    runHook preInstall

    # https://github.com/89luca89/distrobox/issues/408
    substituteInPlace ./distrobox-generate-entry \
    --replace-fail 'icon_default="''${XDG_DATA_HOME:-''${HOME}/.local/share}' "icon_default=\"$out"
    ./install -P $out

    runHook postInstall
  '';

  # https://github.com/89luca89/distrobox/issues/407
  postFixup = ''
    wrapProgram "$out/bin/distrobox-generate-entry" \
      --prefix PATH ":" ${lib.makeBinPath [ wget ]}

    mkdir -p $out/share/distrobox
    echo 'container_additional_volumes="/nix:/nix"' > $out/share/distrobox/distrobox.conf
  '';

  postInstall = ''
    installShellCompletion \
      --cmd distrbox \
      --zsh completions/zsh/_distrobox \
      --bash completions/bash/distrbox
  '';

  meta = with lib; {
    description = "Wrapper around podman or docker to create and start containers";
    longDescription = ''
      Use any linux distribution inside your terminal. Enable both backward and
      forward compatibility with software and freedom to use whatever distribution
      you’re more comfortable with
    '';
    homepage = "https://distrobox.it/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ atila ];
  };
})
