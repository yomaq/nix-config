{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    # import users
    (inputs.self + /users/admin)
    (inputs.self + /users/carln)
  ];
  config = {
    networking.hostName = "blue";
    system.stateVersion = "23.11";
    networking.useDHCP = lib.mkDefault true;

    yomaq = {
      #autoUpgrade.enable = true;
      primaryUser.users = [ "carln" "admin" ];
      _1password.enable = true;
      tailscale.enable = true;
      gnome.enable = true;
      scripts.enable = true;
    };
  };
}
