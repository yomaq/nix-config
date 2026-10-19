{
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
  ];
  config = {
    networking.hostName = "vermilion";
    system.stateVersion = "25.11";

    programs.nix-ld.enable = true;
    virtualisation.podman.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      qemu.vhostUserPackages = [ pkgs.virtiofsd ];
      qemu.swtpm.enable = true;
    };
    users.users.carln.extraGroups = [ "libvirtd" ];
    environment.systemPackages = [ pkgs.swtpm ];

    yomaq = {
      suites.foundation.enable = true;
      network = {
        useBr0 = true;
        physicalInterfaceName = "enp2s0";
      };
      # disk configuration
      disks = {
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = [ "igc" ];
        };
        zfs = {
          enable = true;
          hostID = "69e75bfa";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
