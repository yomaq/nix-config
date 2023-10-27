{ inputs, lib, config, pkgs, ... }: 
let
  hostname = "midnight";
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    {home-manager.useUserPackages = true;}
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
    home-manager = {
      extraSpecialArgs = { inherit inputs; };
      users = {
        # Import your home-manager configuration
        carln = import ../../home-manager/users/carln/carlnMidnight.nix;
      };
    };
  };
}



