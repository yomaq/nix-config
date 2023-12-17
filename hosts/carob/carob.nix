{ config, lib, pkgs, inputs, modulesPath, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
    # hardware
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  config = {
    networking.hostName = "green";
    system.stateVersion = "23.11";
    networking.useDHCP = lib.mkDefault true;
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    yomaq = {
      tailscale.enable = true;
      _1password.enable = true;

      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      timezone.central= true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      # disk configuration
      disks = {
        enable = true;
        systemd-boot.enable = true;
        zfs = {
          enable = true;
          hostID = "7CEA7619";
          root = {
            enable = true;
            encrypt = false;
            disk1 = "mmcblk0";
            impermanenceRoot = true;
            impermanenceHome = true;
          };
        };
      };
    };
  };
}
