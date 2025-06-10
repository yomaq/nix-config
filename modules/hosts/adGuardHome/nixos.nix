{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.adguardhome;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;
in
{
  options.yomaq.adguardhome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom adGuard Home module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."${backup}" = {
      directories = [ "/var/lib" ];
    };
    services.adguardhome = {
      enable = true;
      allowDHCP = true;
    };
    yomaq.homepage.groups.services.services = [
      {
        DNS = {
          icon = "si-adguard";
          href = "{{HOMEPAGE_VAR_ADGUARD_IP}}";
          widget = {
            type = "adguard";
            url = "http://${hostName}.${tailnetName}.ts.net";
            username = "{{HOMEPAGE_VAR_ADGUARD_USERNAME}}";
            password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
          };
        };
      }
    ];
  };
}
