{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "comfyui";
  IMAGE = "docker.io/yanwk/comfyui-boot";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
in
{
  options.yomaq.pods.${NAME} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom ${NAME} container module
      '';
    };
    volumeLocation = lib.mkOption {
      type = lib.types.str;
      default = "${dontBackup}/containers/${NAME}";
      description = ''
        path to store container volumes
      '';
    };
    imageVersion = lib.mkOption {
      type = lib.types.str;
      default = "cu124-slim";
      description = ''
        container image version
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/ollama 0755 root root" ];

    virtualisation.oci-containers.containers = {
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
        };
        volumes = [ "${cfg.volumeLocation}/ollama:/root" ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
          "--device=nvidia.com/gpu=all"
        ];
      };
    };

    yomaq.pods.tailscaled."TS${NAME}" = {
      TSserve = {
        "/" = "http://127.0.0.1:8188";
      };
      tags = [ "tag:ollama-server" ];
    };

    # yomaq.homepage.groups.services.services = [
    #   {
    #     "${NAME}" = {
    #       icon = "si-files";
    #       href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
    #       siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
    #     };
    #   }
    # ];

    yomaq.gatus.endpoints = [
      {
        name = "${hostName}-${NAME}";
        group = "webapps";
        url = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
        interval = "5m";
        conditions = [ "[STATUS] == 200" ];
        alerts = [
          {
            type = "ntfy";
            failureThreshold = 3;
            description = "healthcheck failed";
          }
        ];
      }
    ];
    yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
  };
}
