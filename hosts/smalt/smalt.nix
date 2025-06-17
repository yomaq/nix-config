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
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  config = {
    networking.hostName = "smalt";
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
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    yomaq = {
      suites.foundation.enable = true;
      network = {
        useBr0 = true;
        physicalInterfaceName = "eno1";
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
          hostID = "ab010ea1";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
