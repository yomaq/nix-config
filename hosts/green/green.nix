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
  ];
  config = {
    networking.hostName = "green";
    system.stateVersion = "25.05";
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    yomaq = {
      users.enableUsers = [ "admin" ];

      autoUpgrade.enable = true;
      primaryUser.users = [
        "admin"
      ];
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
        ];
        preApprovedSshAuthkey = true;
      };
      network = {
        useBr0 = true;
        physicalInterfaceName = "enp1s0";
      };
      timezone.central = true;
      syncoid.enable = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      docker.enable = true;
      pods = {
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
          hostID = "a153c64f";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
