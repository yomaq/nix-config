{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    inputs.self.nixosModules.common
    inputs.self.nixosModules.options
    inputs.self.shared.common
    inputs.self.shared.options
  ];
  networking.hostName = "nixos";
  system.stateVersion = "23.05";
  networking.useDHCP = lib.mkDefault true;
  yomaq.users.users = [ admin ];
}
