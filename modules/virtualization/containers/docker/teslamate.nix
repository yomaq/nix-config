{
  config,
  lib,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "teslamate";
  IMAGE = "docker.io/teslamate/teslamate";
  dbIMAGE = "docker.io/postgres";
  grafanaIMAGE = "docker.io/teslamate/grafana";

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
            agenixSecret = lib.mkOption {
              type = lib.types.path;
              default = (inputs.self + /secrets/${NAME}EnvFile.age);
              description = ''
                path to agenix secret file
              '';
            };
            volumeLocation = lib.mkOption {
              type = lib.types.str;
              default = "${backup}/containers/${NAME}";
              description = ''
                path to store container volumes
              '';
            };
            ### database container
            database = {
              agenixSecret = lib.mkOption {
                type = lib.types.path;
                default = (inputs.self + /secrets/${NAME}DBEnvFile.age);
                description = ''
                  path to agenix secret file
                '';
              };
              volumeLocation = lib.mkOption {
                type = lib.types.str;
                default = "${backup}/containers/${NAME}/DB";
                description = ''
                  path to store container volumes
                '';
              };
            };
            ### grafana container
            grafana = {
              agenixSecret = lib.mkOption {
                type = lib.types.path;
                default = (inputs.self + /secrets/${NAME}GrafanaEnvFile.age);
                description = ''
                  path to agenix secret file
                '';
              };
              volumeLocation = lib.mkOption {
                type = lib.types.str;
                default = "${backup}/containers/${NAME}/Grafana";
                description = ''
                  path to store container volumes
                '';
              };
            };
            ### mqtt container
            mqtt = {
              volumeLocation = lib.mkOption {
                type = lib.types.str;
                default = "${backup}/containers/${NAME}/mqtt";
                description = ''
                  path to store container volumes
                '';
              };
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      ### agenix secrets for container
      age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
      age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;
      age.secrets."${NAME}GrafanaEnvFile".file = cfg.grafana.agenixSecret;

      systemd.tmpfiles.rules = [
        # main container
        "d ${cfg.volumeLocation}/import 0755 4000 4000"
        # database container
        "d ${cfg.database.volumeLocation}/teslamate-db 0755 4000 4000"
        # grafana
        "d ${cfg.grafana.volumeLocation}/teslamate-grafana-data 0755 4000 4000"
        # # mqtt
        # "d ${cfg.mqtt.volumeLocation}/mosquitto-data 0755 4000 4000"
        # "d ${cfg.mqtt.volumeLocation}/mosquitto-conf 0755 4000 4000"
      ];
      virtualisation.oci-containers.containers = {
        ### DB container
        "DB${NAME}" = {
          image = "docker.io/postgres:16@sha256:056b54f00419b49289227ab12d09df508543883f407fe9935a2cec430ef8aa8d";
          autoStart = true;
          environment = {
            # "PGUSER" = "teslamate";
          };
          environmentFiles = [
            config.age.secrets."${NAME}DBEnvFile".path
            #  POSTGRES_USER=teslamate
            #  POSTGRES_PASSWORD=password #insert your secure database password!
            #  POSTGRES_DB=teslamate
          ];
          volumes = [ "${cfg.database.volumeLocation}/teslamate-db:/var/lib/postgresql/data" ];
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
        ### Grafana container
        "grafana-${NAME}" = {
          image = "docker.io/teslamate/grafana:latest@sha256:f88cbb90a8c7afa122c6b6851a647edfe7ce7112724db4a8d94853a454f1106a";
          autoStart = true;
          environment = {
            "GF_SERVER_ROOT_URL" = "%(protocol)s://%(domain)s/grafana";
            "GF_SERVER_SERVE_FROM_SUB_PATH" = "true";
            # "GF_SERVER_DOMAIN" = "${config.networking.hostName}-${NAME}.${tailnetName}.ts.net";
          };
          environmentFiles = [
            # container listens on port 3000
            config.age.secrets."${NAME}GrafanaEnvFile".path
            #  DATABASE_USER=teslamate
            #  DATABASE_PASS=password #insert your secure database password!
            #  DATABASE_NAME=teslamate
            #  DATABASE_HOST=database
          ];
          volumes = [ "${cfg.grafana.volumeLocation}/teslamate-grafana-data:/var/lib/grafana" ];
          dependsOn = [
            "TS${NAME}"
            "DB${NAME}"
          ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
          user = "4000:4000";
        };
        # ### Mosquitto (MQTT) container
        #       "mqtt-${NAME}" = {
        #         image = "${mqttIMAGE}:${cfg.mqtt.imageVersion}";
        #         autoStart = true;
        #         cmd = ["mosquitto -c /mosquitto-no-auth.conf"];
        #         environment = {
        #         };
        #         environmentFiles = [];
        #         volumes = [
        #           "${cfg.mqtt.volumeLocation}/mosquitto-data:/mosquitto/data"
        #           "${cfg.mqtt.volumeLocation}/mosquitto-conf:/mosquitto/config"
        #         ];
        #         extraOptions = [
        #           "--network=container:TS${NAME}"
        #         ];
        #         user = "4000:4000";
        #       };
        ### main container
        "${NAME}" = {
          image = "docker.io/teslamate/teslamate:latest@sha256:db111162f1037a8c8ce6fe56e538a4432b8a34d3d6176916ba22d42ef7ee4b78";
          autoStart = true;
          environment = {
            "DISABLE_MQTT" = "true";
            "DATABASE_POOL_SIZE" = "10";
          };
          environmentFiles = [
            config.age.secrets."${NAME}EnvFile".path
            #  ENCRYPTION_KEY=secretkey #replace with a secure key to encrypt your Tesla API tokens
            #  DATABASE_USER=teslamate
            #  DATABASE_PASS=password #insert your secure database password!
            #  DATABASE_NAME=teslamate
            #  DATABASE_HOST=database
            #  MQTT_HOST=mosquitto
          ];
          volumes = [ "${cfg.volumeLocation}/import:/opt/app/import" ];
          dependsOn = [
            "TS${NAME}"
            "DB${NAME}"
          ];
          extraOptions = [
            "--cap-drop=all"
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
      };
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:4000";
          "/grafana" = "http://127.0.0.1:3000/grafana";
        };
        tags = [ "tag:teslamate" ];
      };
      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
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
    (lib.mkIf config.yomaq.homepage.enable {
      yomaq.homepage.groups.services = builtins.listToAttrs (
        map
          (host: {
            name = "${NAME} - ${host}";
            value = {
              icon = "si-tesla";
              href = "https://${host}-${NAME}.${tailnetName}.ts.net/";
              siteMonitor = "https://${host}-${NAME}.${tailnetName}.ts.net/";
            };
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.pods."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          )
      );
    })
  ];
}
