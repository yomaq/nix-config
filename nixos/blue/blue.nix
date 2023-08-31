{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      ./configuration.nix
      ./hardware-configuration.nix
      ./gnome.nix
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-hardware.nixosModules.lenovo-legion-15ach6
      inputs.agenix.nixosModules.default
    ];
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  #age.identityPaths = [ "/home/carln/.ssh/agenix" ];
  #age.secrets.secret1.file = ./secret1.age;
    #neededForUsers = true;

  users.users.carln = {
    isNormalUser = true;
    description = "carln";
    # passwordFile = config.age.secrets.secret1.path;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
#  users.users.carln2 = {
#    isNormalUser = true;
#    description = "carln2";
#    passwordFile = config.age.secrets.secret1.path;
#    extraGroups = [ "networkmanager" "wheel" ];
#    packages = with pkgs; [];
#  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      carln = import ../.././home-manager/carlnBlue.nix;
    };
  };

  # automatically rebuild system if github has updates
  system.autoUpgrade = {
    enable = true;
    flake = github:yomaq/nix-config;
    flags = ["-L" ]; # print build logs 
    dates = "02:00";
  };



  
  # Apparently... nixos can't declaratively manage flatpaks????????
  services.flatpak.enable = true;
}
