{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    inputs.self.nixosModules.common
    #inputs.self.nixosModules.options
    #inputs.self.shared.common
    #inputs.self.shared.options
    (inputs.self + "nixos/users/admin-ssh-only.nix")
  ];
  config = {
    networking.hostName = "nixos";
    system.stateVersion = "23.05";
    networking.useDHCP = lib.mkDefault true;
    #yomaq.users.users = [ "admin" ];
  };
}
