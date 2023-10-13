# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, lib, config, pkgs, ... }: 
let
  hostname = "midnight";
in
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    inputs.home-manager.darwinModules.home-manager
    inputs.self.darwinModules.test
    ../modules/common
    {
      home-manager.useUserPackages = true;
    }
    # You can also split up your configuration and import pieces of it here by linking its location directly:
    # ./folder/location
  ];

  config = {
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