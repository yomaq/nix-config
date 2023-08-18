# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    inputs.home-manager.darwinModules.home-manager
    inputs.self.homeConfigurations."carln@midnight".nixosModule
    inputs.self.darwinModules.current
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
    # You can also split up your configuration and import pieces of it here by linking its location directly:
    # ./folder/location
  ];

  # fix for home manager bug
  config = {
    networking = {
      computerName = "midnight";
      localHostName = "midnight";
    };
    system = {
      defaults = {
        smb = {
          NetBIOSName = "midnight";
          ServerDescription = "midnight";
        };
      };
    };
  };
}