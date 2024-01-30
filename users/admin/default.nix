{ config, lib, pkgs, modulesPath, inputs, ... }:
let
  inherit (config.yomaq.impermanence) dontBackup;
in
{
  imports = [
    inputs.self.homeManagerModules.yomaq
  ];

  yomaq.ssh.enable = true;
  # Force all user accounts to require nix configuration, any manual changes to users will be lost
  users.mutableUsers = false;
  # Configure admin account
  users.users.admin = {
    isNormalUser = true;
    description = "admin";
    # disable password for admin account
    hashedPassword = null;
    # Set authorized keys to authenticate to ssh as admin user
    openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
        ];
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
  };
  # Enable admin account to use ssh without password (since the admin account doesn't HAVE a password)
  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];
  environment.persistence."${dontBackup}" = {
    users.admin = {
      directories = [
        "nix"
        "documents"
      ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      admin = import ./homeManager;
    };
  };
}