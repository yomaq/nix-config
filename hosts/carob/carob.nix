{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
    # hardware
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  config = {
    networking.hostName = "green";
    system.stateVersion = "23.11";
    networking.useDHCP = lib.mkDefault true;
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    yomaq = {
      tailscale.enable = true;
      _1password.enable = true;

      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      timezone.central= true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
    };
  };
}
