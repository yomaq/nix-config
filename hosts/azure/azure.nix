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
      podman.enable = true;
      pods = {
        minecraft.enable = true;
        nextcloud.enable = true;
      };
      syncoid.isBackupServer = true;
      syncoid.exclude = ["blue"];
    };
  };
}
