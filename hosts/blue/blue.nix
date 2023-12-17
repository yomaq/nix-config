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
    system.stateVersion = "23.05";
    networking.useDHCP = lib.mkDefault true;

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "carln" "admin" ];
      _1password.enable = true;
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true" ];
      };
      gnome.enable = true;
      scripts.enable = true;
      flatpak.enable = true;
      timezone.central= true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
    };
  };
}
