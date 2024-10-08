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
    system.stateVersion = "23.05";

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
          "--accept-dns=true"
          "--advertise-exit-node=true"
        ];
        useRoutingFeatures = "server";
      };
      glances.enable = lib.mkForce false;
      _1password.enable = true;
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
          ethernetDrivers = [ "e1000e" ];
        };
        zfs = {
          enable = true;
          hostID = "2C2883D7";
          root = {
            disk1 = "nvme0n1";
            impermanenceRoot = true;
          };
        };
      };
    };
  };
}
