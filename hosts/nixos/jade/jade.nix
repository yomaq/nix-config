{
  lib,
  inputs,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
  ];
  config = {
    networking.hostName = "jade";
    system.stateVersion = "25.05";

    yomaq = {
      suites.foundation.enable = true;
      network = {
        useBr0 = true;
        physicalInterfaceName = "enp1s0";
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
          hostID = "90b142c5";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
