{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.ssh;
in
{
  options.yomaq.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom ssh module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable SSH service
    networking.firewall.allowedTCPPorts = [ 22 ];
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
      ];
    };
  };
}
