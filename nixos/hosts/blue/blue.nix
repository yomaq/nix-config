{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      ./configuration.nix
      ./hardware-configuration.nix
      ./gnome.nix
      inputs.nixos-hardware.nixosModules.lenovo-legion-15ach6
      # user account
      ../../users/carln.nix
    ];
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      # Add community cache
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
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
