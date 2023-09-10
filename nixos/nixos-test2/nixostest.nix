{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      ./configuration.nix
      ./zfs.nix
      inputs.disko.nixosModules.disko
      #inputs.home-manager.nixosModules.home-manager
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
  networking.hostId = "83b0a257"; # for ZFS
  disko.devices = import ./disko-zfs.nix {
    lib = inputs.nixpkgs.lib;
  };


services.openssh.enable = true;
users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEYoH0dcCQP4sFB3Jl3my7tqXdcwvHo0mOdDdB39UFX" ];
#  home-manager = {
#    extraSpecialArgs = { inherit inputs; };
#    users = {
#      # Import your home-manager configuration
#      carln = import .././home-manager/carlnMidnight.nix;
#    };
#  };
}
