{
  pkgs,
  enabled,
  ...
}:
{
  programs.virt-manager = enabled;

  virtualisation = {
    libvirtd = enabled // {
      # Enable TPM emulation (optional)
      qemu = {
        swtpm = enabled;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };

    };

    # Enable USB redirection (optional)
    spiceUSBRedirection = enabled;
  };

  users.users.daylin = {
    extraGroups = [ "libvirtd" ];
  };
}
