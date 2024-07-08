# pkg: https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/fail3ban/default.nix
# module: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/security/fail2ban.nix

{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  installShellFiles,
}:
let

  rev = "8170e9fe75fd2c2c4c51a1d9972b683401cddccb";
in

python3.pkgs.buildPythonApplication {
  pname = "fail2ban";
  # version = "1.0.2";
  version = "1.1.0-${builtins.substring 0 8 rev}";

  src = fetchFromGitHub {
    owner = "fail2ban";
    repo = "fail2ban";
    hash = "sha256-cOHpUPEEp3FoRjywun205ugbV+I51EWVTGwZS0jNRwE=";
    # rev = version;
    inherit rev;
  };

  outputs = [
    "out"
    "man"
  ];

  nativeBuildInputs = [ installShellFiles ];

  pythonPath = lib.optionals stdenv.isLinux (
    with python3.pkgs;
    [
      systemd
      pyinotify
    ]
  );

  preConfigure = ''
    for i in config/action.d/sendmail*.conf; do
      substituteInPlace $i \
        --replace /usr/sbin/sendmail sendmail
    done

    substituteInPlace config/filter.d/dovecot.conf \
      --replace dovecot.service dovecot2.service
  '';

  doCheck = false;

  preInstall = ''
    substituteInPlace setup.py --replace /usr/share/doc/ share/doc/

    # see https://github.com/NixOS/nixpkgs/issues/4968
    ${python3.pythonOnBuildForHost.interpreter} setup.py install_data --install-dir=$out --root=$out
  '';

  postInstall =
    let
      sitePackages = "$out/${python3.sitePackages}";
    in
    ''
      install -m 644 -D -t "$out/lib/systemd/system" build/fail2ban.service
      # Replace binary paths
      sed -i "s#build/bdist.*/wheel/fail2ban.*/scripts/#$out/bin/#g" $out/lib/systemd/system/fail2ban.service
      # Delete creating the runtime directory, systemd does that
      sed -i "/ExecStartPre/d" $out/lib/systemd/system/fail2ban.service

      # see https://github.com/NixOS/nixpkgs/issues/4968
      rm -r "${sitePackages}/etc"

      installManPage man/*.[1-9]

      # This is a symlink to the build python version created by `updatePyExec`, seemingly to assure the same python version is used?
      rm $out/bin/fail2ban-python
      ln -s ${python3.interpreter} $out/bin/fail2ban-python

    ''
    + lib.optionalString stdenv.isLinux ''
      # see https://github.com/NixOS/nixpkgs/issues/4968
      rm -r "${sitePackages}/usr"
    '';

  meta = with lib; {
    homepage = "https://www.fail2ban.org/";
    description = "Program that scans log files for repeated failing login attempts and bans IP addresses";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      eelco
      lovek323
    ];
  };
}
