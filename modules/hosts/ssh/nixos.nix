{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.ssh;
in
{
  config = lib.mkIf cfg.enable {
    services.openssh = {
      settings = {
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
