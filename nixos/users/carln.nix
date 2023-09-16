{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default
    ];
  age.identityPaths = [ "/home/carln/.ssh/agenix" ];
  age.secrets.carln.file = ../../../secrets/carln.age;

  users.mutableUsers = false;

  users.users.carln = {
    isNormalUser = true;
    description = "carln";
    hashedPasswordFile = config.age.secrets.carln.path;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      carln = import ../../../home-manager/users/carln/carlnBlue.nix;
    };
  };
}