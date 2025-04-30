{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

### not working

with lib;
let
  ### Set container name and image
  NAME = "neko";
  IMAGE = "m1k1o/neko";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;

in
{
  options.yomaq.pods.${NAME} = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom ${NAME} container module
      '';
    };
    volumeLocation = mkOption {
      type = types.str;
      default = "${backup}/containers/${NAME}";
      description = ''
        path to store container volumes
      '';
    };
    imageVersion = mkOption {
      type = types.str;
      default = "firefox";
      description = ''
        container image version
      '';
    };
  };

  config = mkIf cfg.enable {

    systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/data 0755 root root" ];

    virtualisation.oci-containers.containers = {
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        volumes = [
          "${cfg.volumeLocation}/data:/home/neko/.mozilla/firefox/profile.default"
        ];
        environment = {
          "NEKO_SCREEN" = "1920x1080@30";
          "NEKO_PASSWORD" = "neko";
          "NEKO_PASSWORD_ADMIN" = "admin";
          # "NEKO_EPR" = "52000-52100";
          "NEKO_UDPMUX" = "52001";
          "NEKO_ICELITE" = "1";
          "NEKO_PROXY" = "true";
          "NEKO_NAT1TO1" = "100.71.89.119";
        };
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
          "--shm-size=2gb"
        ];
      };
    };

    yomaq.pods.tailscaled."TS${NAME}" = {
      TSserve = {
        "/" = "http://127.0.0.1:8080";
      };
      tags = [ "tag:generichttps" ];
    };

    yomaq.homepage.groups.services.services = [
      {
        "${NAME}" = {
          icon = "netflix";
          href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
        };
      }
    ];
  };
}
