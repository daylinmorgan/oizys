{
  inputs,
  pkgs,
  flake,
  enabled,
  ...
}:
let
  inherit (inputs) NixVirt;
  defaultNetwork = {
    definition = NixVirt.lib.network.writeXML (
      NixVirt.lib.network.templates.bridge {
        uuid = "e7955c23-8750-4405-ab2c-37aeee441f67";
        subnet_byte = 24;
      }
    );
  };
in
{
  imports = [
    (flake.module "NixVirt")
  ];

  programs.virt-manager = enabled;

  virtualisation = {
    libvirt = enabled // {
      swtpm = enabled;
      connections."qemu:///system" = {
        networks = [ defaultNetwork ];
        domains = [
          { definition = ./win11.xml; }
        ];
      };
    };
    libvirtd.qemu = {
      # ovmf.packages = [ pkgs.OVMFFull.fd ];
      vhostUserPackages = [ pkgs.virtiofsd ];
    };

    # Enable USB redirection (optional)
    spiceUSBRedirection = enabled;
  };

  users.users.daylin = {
    extraGroups = [ "libvirtd" ];
  };
}
