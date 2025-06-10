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
    inputs.self.nixosModules.pods
    # import hardware
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-laptop
  ];
  config = {
    networking.hostName = "azure";
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
      docker.enable = true;
      pods = {
        golink.enable = true;
        teslamate.enable = true;
        dufs.enable = true;
        changedetection.enable = true;
        linkwarden.enable = true;
        searxng.enable = true;
        n8n.enable = true;
        open-webui.enable = true;
      };
      nixos-containers = {
        nextcloud = {
          enable = true;
          storage = config.yomaq.impermanence.backupStorage;
        };
        homepage.enable = true;
        ntfy.enable = true;
        gatus.enable = true;
        tsidp.enable = true;
        audiobookshelf.enable = true;
      };
      syncoid = {
        isBackupServer = true;
        exclude = [
          "blue"
          "green"
          "wsl"
        ];
      };
      network = {
        useBr0 = true;
        physicalInterfaceName = "eno1";
      };
      timezone.central = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      disks = {
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
            disk2 = "nvme1n1";
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
            #amReinstalling = true;
          };
        };
      };
    };
  };
}
