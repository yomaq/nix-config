{ options, config, lib, pkgs, ... }:
with lib;
let
  cfg = config.yomaq.adguardhome;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;
in
{
  options.yomaq.adguardhome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom adGuard Home module
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.persistence."${backup}" = {
      directories = [
        "/var/lib"
      ];
    };
    services.adguardhome = {
      enable = true;
      allowDHCP = true;
      extraArgs = ["--web-addr ${hostName}.${tailnetName}.ts.net:3000"];
    };
    yomaq.homepage.groups.services.utilities = [{
      DNS = {
        href = "http://${hostName}.${tailnetName}.ts.net:3000";
        icon = "si-adguard";
        widget = {
          type = "adguard";
          url = "http://${hostName}.${tailnetName}.ts.net";
          username = "{{HOMEPAGE_VAR_ADGUARD_USERNAME}}";
          password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
        };
      };
    }];
  };
}