{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
  ];
  config = {
    networking.hostName = "azure";
    system.stateVersion = "23.11";
    networking.useDHCP = lib.mkDefault true;

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      tailscale.enable = true;
      docker = {
        enable = true;
      };
      pods = {
        minecraft.enable = true;
        nextcloud.enable = true;
        traefik.enable = true;
      };
      syncoid.isBackupServer = true;
      syncoid.exclude = ["blue"];
      timezone.central= true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
    };
  };
}
