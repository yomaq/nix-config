{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "searxng";
  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

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
              default = "latest";
              description = ''
                container image version
              '';
            };
            hostname = lib.mkOption {
              type = lib.types.str;
              default = "search.your.domain.com";
              description = ''
                hostname for SearXNG
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.volumeLocation}/searxng 0755 4000 4000"
        "d ${cfg.volumeLocation}/valkey-data 0755 4000 4000"
      ];

      virtualisation.oci-containers.containers = {
        "${NAME}-redis" = {
          image = "docker.io/valkey/valkey:8-alpine";
          autoStart = true;
          volumes = [ "${cfg.volumeLocation}/valkey-data:/data" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
            "--cap-add=SETGID"
            "--cap-add=SETUID"
            "--cap-add=DAC_OVERRIDE"
            "--cap-drop=ALL"
          ];
          user = "4000:4000";
          cmd = [
            "valkey-server"
            "--save"
            "30"
            "1"
            "--loglevel"
            "warning"
          ];
        };

        "${NAME}" = {
          image = "docker.io/searxng/searxng:${cfg.imageVersion}";
          autoStart = true;
          volumes = [ "${cfg.volumeLocation}/searxng:/etc/searxng:rw" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
            "--cap-add=CHOWN"
            "--cap-add=SETGID"
            "--cap-add=SETUID"
            "--cap-drop=ALL"
          ];
          user = "4000:4000";
          environment = {
            SEARXNG_BASE_URL = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
            UWSGI_WORKERS = "2";
            UWSGI_THREADS = "2";
          };
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
            icon = "si-searxng";
            href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
            siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          };
        }
      ];

      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
      yomaq.monitorServices.services."docker-${NAME}-redis".priority = "medium";
    })
    (lib.mkIf config.yomaq.gatus.enable {
      yomaq.gatus.endpoints =
        map
          (host: {
            name = "${host}-${NAME}";
            group = "webapps";
            url = "https://${host}-${NAME}.${config.yomaq.tailscale.tailnetName}.ts.net";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [
              {
                type = "ntfy";
                failureThreshold = 3;
                description = "healthcheck failed";
              }
            ];
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.pods."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          );
    })
  ];
}
