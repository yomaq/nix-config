{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.smartd;
  ntfyScript = pkgs.writeShellScript "smartd-ntfy" ''
    ${pkgs.curl}/bin/curl -H "Title: SMART Error on $(hostname)" \
      -H "Priority: high" \
      -H "Tags: warning,disk" \
      -d "$SMARTD_MESSAGE" \
      "${config.yomaq.ntfy.ntfyUrl}/${cfg.ntfyTopic}"
  '';
in
{
  options.yomaq.smartd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable smartd monitoring with ntfy notifications
      '';
    };
    ntfyTopic = lib.mkOption {
      type = lib.types.str;
      default = "zfs";
      description = ''
        ntfy topic for smartd notifications
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      notifications = {
        mail.enable = false;
        wall.enable = false;
      };
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04) -M exec ${ntfyScript} -m <nomailer>";
    };
  };
}
