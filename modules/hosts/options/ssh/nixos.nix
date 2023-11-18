{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.ssh;
  inherit (config.networking) hostName;
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
          path = "/etc/ssh/${hostName}";
          type = "ed25519";
        }
      ];
    };
  };
}