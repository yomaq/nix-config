{
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
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  config = {
    networking.hostName = "teal";
    system.stateVersion = "23.11";
    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    yomaq = {
      suites.foundation.enable = true;
      network = {
        useBr0 = true;
        physicalInterfaceName = "eno2";
      };
      # disk configuration
      disks = {
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = [ "e1000e" ];
        };
        zfs = {
          enable = true;
          hostID = "f572ff3a";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
