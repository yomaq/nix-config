{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      # modules specific to this computer
      ./misc.nix
      ./hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.lenovo-legion-15ach6
      # user accounts
      ../../users/carln.nix
      ../../users/admin-ssh-only.nix
      # shared modules
      ../../modules/common
      ../../modules/gnome.nix
    ];
  

  system.stateVersion = "23.05";


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "blue"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
}
