{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  hostname = "midnight";
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.self.darwinModules.yomaq
    { home-manager.useUserPackages = true; }
  ];
  config = {
    system.stateVersion = 4;
    networking = {
      computerName = hostname;
      localHostName = hostname;
    };
    system = {
      defaults = {
        smb = {
          NetBIOSName = hostname;
          ServerDescription = hostname;
        };
      };
    };
    yomaq = {
      users.enableUsers = [ "carln" ];

      yabai.enable = true;
      tailscale.enable = true;
      _1password.enable = true;
      scripts.enable = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      agenix.enable = lib.mkDefault false;
    };
  };
}
