{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [];

  # Enable SSH service
  networking.firewall.allowedTCPPorts = [22];
  services.openssh = {
      enable = true;
      settings = {
        # Disable password ssh authentication
        PasswordAuthentication = false;
      };
    };
}