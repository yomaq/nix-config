{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.ssh;
in
{
  options.yomaq.ssh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom ssh module
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable SSH service
    networking.firewall.allowedTCPPorts = [22];
    services.openssh = {
      enable = true;
      settings = {
        # Disable password ssh authentication
        PasswordAuthentication = false;
      };
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
        { file = "/etc/ssh/ssh/ssh_host_ed25519_key"; }
        { file = "/etc/ssh/ssh/ssh_host_rsa_key"; }
      ];
    };
  };
}