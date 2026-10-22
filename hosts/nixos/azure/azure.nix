{
  config,
  lib,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
    # hardware
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
  ];
  config = {
    networking.hostName = "azure";
    system.stateVersion = "26.05";

    yomaq = {
      network = {
        useBr0 = true;
        physicalInterfaceName = "eno1";
      };
      suites.foundation.enable = true;
      disks = {
        # amReinstalling = true;
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = [ "igc" ];
        };
        zfs = {
          enable = true;
          hostID = "49e95c43";
          root = {
            disk1 = "nvme0n1";
            reservation = "200G";
            impermanenceRoot = true;
          };
          storage = {
            enable = true;
            disks = [
              "sda"
              "sdb"
            ];
            reservation = "1500G";
            mirror = true;
          };
        };
      };
    };
  };
}
