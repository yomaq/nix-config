{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [];
  # Enable ssh
  yomaq.ssh.enable = true;
  # Force all user accounts to require nix configuration, any manual changes to users will be lost
  users.mutableUsers = false;
  # Configure admin account
  users.users.admin = {
    extraGroups = [ "networkmanager" "wheel" ];
    isNormalUser = true;
    description = "admin";
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
  # packages to make available to admin
  users.users.admin.packages = with pkgs; [
    git
    vim
    gh
    tailscale
  ];
}