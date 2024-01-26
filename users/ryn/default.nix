{ config, lib, pkgs, modulesPath, inputs, ... }:
let
  inherit (config.yomaq.impermanence) dontBackup;
in
{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
    ];
  age.secrets.ryn.file = (inputs.self + /secrets/ryn.age);

  users.mutableUsers = false;

  users.users.ryn = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "ryn";
    hashedPasswordFile = config.age.secrets.ryn.path;
    extraGroups = [];
    openssh.authorizedKeys.keys = [];
    packages = with pkgs; [];
  };

  environment.persistence."${dontBackup}" = {
    users.ryn = {
      directories = [
        "documents"
        "desktop"
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
      ryn = import ./homeManager;
    };
  };
}