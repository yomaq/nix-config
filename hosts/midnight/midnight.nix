{
  inputs,
  lib,
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
      hostName = hostname;
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

    system.primaryUser = "carln";
    ids.gids.nixbld = 350;

    yomaq = {
      users.enableUsers = [ "carln" ];
      yabai.enable = true;
      tailscale.enable = true;
      _1password.enable = true;
      scripts.enable = true;
      suites.foundation.enable = true;
      agenix.enable = lib.mkDefault false;
    };
  };
}
