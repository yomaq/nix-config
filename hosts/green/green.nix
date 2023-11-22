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
    networking.hostName = "green";
    system.stateVersion = "23.05";
    networking.useDHCP = lib.mkDefault true;

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      _1password.enable = true;
      tailscale.enable = true;
      #pods.tailscale.enable = true;
    };
  };
}
