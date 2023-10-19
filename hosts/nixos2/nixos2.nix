{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    self.inputs.nixosModules.common
    self.inputs.nixosModules.options
    self.inputs.shared.common
    self.inputs.shared.options
  ];
  networking.hostName = "nixos";
  system.stateVersion = "23.05";
  networking.useDHCP = lib.mkDefault true;
  yomaq.users.users = [ admin ];
}
