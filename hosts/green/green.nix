{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
  ];
  config = {
    networking.hostName = "green";
    system.stateVersion = "23.11";

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
          "--accept-dns=true"
        ];
        useRoutingFeatures = "server";
      };
      timezone.central = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      # disk configuration
      disks = {
        enable = true;
        systemd-boot = true;
        initrd-ssh = {
          enable = true;
          ethernetDrivers = [ "r8169" ];
        };
        zfs = {
          enable = true;
          hostID = "cefcf5c9";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
