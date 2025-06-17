{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "golink";
  IMAGE = "ghcr.io/tailscale/golink";

  cfg =
    if config ? inventory.hosts."${config.networking.hostName}".pods.${NAME} then
      config.inventory.hosts."${config.networking.hostName}".pods.${NAME}
    else
      null;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.pods.${NAME} = {
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
            imageVersion = lib.mkOption {
              type = lib.types.str;
              default = "main";
              description = ''
                container image version
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg != null && cfg.enable) {

      systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/data 0755 4000 4000" ];

      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "${IMAGE}:${cfg.imageVersion}";
          autoStart = true;
          volumes = [ "${cfg.volumeLocation}/data:/home/nonroot" ];
          extraOptions = [
            "--pull=always"
          ];
          user = "4000:4000";
        };
      };

      # yomaq.pods.tailscaled."TS${NAME}" = {
      #   TSserve = {
      #     "/" = "http://127.0.0.1:5000";
      #   };
      #   tags = [ "tag:generichttps" ];
      # };

      yomaq.homepage.groups.services.services = [
        {
          "${NAME}" = {
            icon = "si-go";
            href = "https://go.${tailnetName}.ts.net";
            siteMonitor = "https://go.${tailnetName}.ts.net";
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
