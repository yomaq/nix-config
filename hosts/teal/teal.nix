{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    # import users
    (inputs.self + /users/admin)
    (inputs.self + /users/carln)
    # hardware
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
  ];
  config = {
    networking.hostName = "teal";
    system.stateVersion = "23.11";
    networking.useDHCP = lib.mkDefault true;

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "carln" "admin" ];
      _1password.enable = true;
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true" "--exit-node=100.82.151.77" "--exit-node-allow-lan-access=true" ];
        useRoutingFeatures = "client";
      };
      gnome.enable = true;
      scripts.enable = true;
      flatpak.enable = true;
      timezone.central= true;
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
