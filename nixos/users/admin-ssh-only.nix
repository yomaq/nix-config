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
  # Force all user accounts to require nix configuration, any manual changes to users will be lost
  user.mutableUsers = false;
  # Configure admin account
  users.users.admin = {
    # disable password for admin account
    hashedPassword = null;
    # Set authorized keys to authenticate to ssh as admin user
    openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
        ];
  };
  # Enable admin account to use ssh without password (since the admin account doesn't HAVE a password)
  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];
}