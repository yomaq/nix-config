{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    inputs.self.users.yomaq
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
      users.enableUsers = [ "admin" ];

      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
        ];
      };
      timezone.central = true;
      syncoid.enable = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      network = {
        useBr0 = true;
        physicalInterfaceName = "eno1";
      };
      docker.enable = true;
      pods = {
        minecraftBedrock.minecrafthome = {
          enable = true;
          envVariables =  {
            "version" = "1.21.60.10";
            "EULA" = "TRUE";
            "gamemode" = "survival";
            "difficulty" = "hard";
            "allow-cheats" = "true";
            "max-players" = "10";
            "view-distance" = "50";
            "tick-distance" = "4";
            "TEXTUREPACK_REQUIRED" = "true";
          };
        };
        factorio.factoriotwo.enable = true;
        factorio.factoriothree.enable = true;
        satisfactory.satisfactoryhome.enable = true;
        satisfactory.satisfactorytwo = {
          enable = true;
          envVariables = {
            "MAXPLAYERS" = "8";
            "STEAMBETA" = "false";
            "AUTOSAVENUM" = "20";
          };
        };
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
