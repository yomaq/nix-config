{ config, lib, pkgs, inputs, modulesPath, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
    # hardware
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  config = {
    networking.hostName = "teal";
    system.stateVersion = "23.11";
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    
    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "carln" "admin" ];
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true" "--advertise-exit-node"];
        useRoutingFeatures = "server";
      };
      timezone.central= true;
      syncoid.enable = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      docker.enable = true;
      pods = {
        minecraftBedrock.minecrafttest.enable = true;
      };

      # disk configuration
      disks = {
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = ["e1000e"];
        };
        zfs = {
          enable = true;
          hostID = "f572ff3a";
          root = {
            enable = true;
            disk1 = "nvme0n1";
            impermanenceRoot = true;
            impermanenceHome = true;
          };
        };
      };
    };
  };
}
