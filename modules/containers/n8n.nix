{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "n8n";
  IMAGE = "docker.io/n8nio/n8n";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
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
      default = "${backup}/containers/${NAME}";
      description = ''
        path to store container volumes
      '';
    };
    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        "WEBHOOK_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
        "N8N_DIAGNOSTICS_ENABLED" = "false";
      };
      description = ''
        env options
      '';
    };
    imageVersion = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = ''
        container image version
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/n8n_data 0755 1000 1000" ];

      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "${IMAGE}:${cfg.imageVersion}";
          autoStart = true;
          environment = cfg.env;
          volumes = [ "${cfg.volumeLocation}/n8n_data:/home/node/.n8n" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
      };

      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:5678";
        };
        tags = [
          "tag:ollama-server"
          "tag:ollama-access"
        ];
      };

      yomaq.homepage.groups.services.services = [
        {
          "${NAME}" = {
            icon = "si-n8n";
            href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
            siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          };
        }
      ];

      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
    })
    (lib.mkIf config.yomaq.gatus.enable {
      # Add dufs to the list of services to monitor
      yomaq.gatus.endpoints = {
        ${NAME} = {
          path = "pods.${NAME}.enable";
          config = {
            group = "webapps";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [
              {
                type = "ntfy";
                failureThreshold = 3;
                description = "healthcheck failed";
              }
            ];
          };
        };
      };
    })
  ];
}
