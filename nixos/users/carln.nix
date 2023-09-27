{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default
      ../modules/ssh.nix
    ];
  age.identityPaths = [ "/home/carln/.ssh/agenix" ];
  age.secrets.carln.file = ../../secrets/carln.age;

  users.mutableUsers = false;

  users.users.carln = {
    isNormalUser = true;
    description = "carln";
    hashedPasswordFile = config.age.secrets.carln.path;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI" 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDtqEBDvaOC75XewBPGx2F6OszVeKItfro2w1NKW5wy"
      ];
    packages = with pkgs; [];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      carln = import ../../home-manager/users/carln/carlnBlue.nix;
    };
  };
}