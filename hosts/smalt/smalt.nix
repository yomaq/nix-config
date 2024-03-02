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
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  config = {
    networking.hostName = "smalt";
    system.stateVersion = "23.11";
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    
    yomaq = {
      autoUpgrade.enable = false;
      primaryUser.users = [ "admin" ];
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true"];
      };
      timezone.central= true;
      syncoid.enable = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      docker.enable = true;
      pods = {
        # valheim.enable = true;
        minecraft.enable = true;
        palworld.enable = true;
        tailscale = {
          enable = true;
          TSargs = "--reset=true --advertise-exit-node";
        };
      };

      # disk configuration
      disks = {
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = ["igc"];
        };
        zfs = {
          enable = true;
          hostID = "ab010ea1";
          root = {
            enable = true;
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
