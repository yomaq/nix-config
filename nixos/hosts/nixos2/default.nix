{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      ./configuration.nix
      ./tmpfs.nix
      ../../users/admin-ssh-only.nix
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

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };
  environment.persistence."/persistent" = {
    hideMounts = true;
    files = [
      { file = "/etc/ssh/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      { file = "/etc/ssh/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
  };



}
