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
    # import users
    (inputs.self + /users/admin)
    # hardware
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-intel
  ];
  config = {
    networking.hostName = "pearl";
    system.stateVersion = "23.11";
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
      "ufshcd-pci"
    ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
        ];
        useRoutingFeatures = "client";
        authKeyFile = null;
      };

      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      timezone.central = true;
      syncoid.enable = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      # disk configuration
      disks = {
        enable = true;
        systemd-boot = true;
        zfs = {
          enable = true;
          hostID = "3F8C6B19";
          root = {
            encrypt = false;
            disk1 = "disk/by-id/scsi-2SAMSUNG";
            impermanenceRoot = true;
          };
        };
      };
    };

    # # Simple test service that fails every 5 seconds
    # systemd.services.test-failure = {
    #   description = "Test service that fails every 5 seconds";
    #   wantedBy = [ "multi-user.target" ];
      
    #   serviceConfig = {
    #     Type = "simple";
    #     Restart = "always";
    #     RestartSec = 5;
    #   };
      
    #   script = ''
    #     #!/bin/sh
    #     echo "Test service running at $(date)"
    #     echo "This service will now fail"
    #     exit 1
    #   '';
    # };
    
    # # Add to monitoring
    # yomaq.monitorServices.services.test-failure = {
    #   topic = "test";
    # };

  };
}
