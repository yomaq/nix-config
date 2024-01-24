{ config, lib, pkgs, modulesPath, inputs, ... }:
let
  inherit (config.yomaq.impermanence) dontBackup;
in
{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
    ];
  age.secrets.carln.file = (inputs.self + /secrets/carln.age);

  users.mutableUsers = false;

  users.users.carln = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "carln";
    hashedPasswordFile = config.age.secrets.carln.path;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI"
      ];
    packages = with pkgs; [];
  };

  environment.persistence."${dontBackup}" = {
    users.carln = {
      directories = [
        "nix"
        "documents"
        ".var"
        ".config"
        ".local"
      ];
    files = [
    ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      carln = import ./homeManager;
    };
  };
}