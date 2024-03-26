{ config, lib, pkgs, inputs, modulesPath, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    # import hardware
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.lenovo-legion-15ach6
    # import users
    (inputs.self + /users/admin)
    (inputs.self + /users/carln)
    (inputs.self + /users/ryn)
  ];
  config = {
    networking.hostName = "blue";
    system.stateVersion = "23.11";
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "carln" "admin" ];
      _1password.enable = true;
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true" ];
        useRoutingFeatures = "client";
        # for building iso
        preApprovedSshAuthkey = true;
      };
      glances.enable = lib.mkForce false;
      gnome.enable = true;
      scripts.enable = true;
      flatpak.enable = true;
      timezone.central= true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      disks = {
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = ["r8169"];
        };
        zfs = {
          enable = true;
          hostID = "CF3C23BE";
          root = {
            enable = true;
            disk1 = "nvme0n1";
            disk2 = "nvme1n1";
            reservation = "200G";
            mirror = true;
            impermanenceRoot = true;
            # impermanenceHome = true;
          };
        };
      };
    };
  };
}
