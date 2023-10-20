{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    inputs.self.nixosModules.common
    inputs.self.nixosModules.options
    inputs.self.sharedModules.common
    inputs.self.sharedModules.options
    (inputs.self + /users/admin)
  ];
  config = {
    networking.hostName = "nixos";
    system.stateVersion = "23.05";
    networking.useDHCP = lib.mkDefault true;
  };
}
