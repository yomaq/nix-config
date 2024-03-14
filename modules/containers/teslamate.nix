
{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "teslamate";
  IMAGE = "docker.io/teslamate/teslamate";
  dbIMAGE = "docker.io/postgres";
  grafanaIMAGE = "docker.io/teslamate/grafana";
  mqttIMAGE = "docker.io/eclipse-mosquitto";


  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
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
    agenixSecret = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/${NAME}EnvFile.age);
      description = ''
        path to agenix secret file
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
      default = "latest";
      description = ''
        container image version
      '';
    };
### database container
    database = {
      agenixSecret = mkOption {
        type = types.path;
        default = (inputs.self + /secrets/${NAME}DBEnvFile.age);
        description = ''
          path to agenix secret file
        '';
      };
      volumeLocation = mkOption {
        type = types.str;
        default = "${backup}/containers/${NAME}/DB";
        description = ''
          path to store container volumes
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "16";
        description = ''
          container image version
        '';
      };
    };
### grafana container
    grafana = {
      agenixSecret = mkOption {
        type = types.path;
        default = (inputs.self + /secrets/${NAME}GrafanaEnvFile.age);
        description = ''
          path to agenix secret file
        '';
      };
      volumeLocation = mkOption {
        type = types.str;
        default = "${backup}/containers/${NAME}/Grafana";
        description = ''
          path to store container volumes
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "latest";
        description = ''
          container image version
        '';
      };
    };
### mqtt container
    mqtt = {
      volumeLocation = mkOption {
        type = types.str;
        default = "${backup}/containers/${NAME}/mqtt";
        description = ''
          path to store container volumes
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "2";
        description = ''
          container image version
        '';
      };
    };
  };

  config = mkIf cfg.enable {
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
        image = "${dbIMAGE}:${cfg.database.imageVersion}";
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
        volumes = [
          "${cfg.database.volumeLocation}/teslamate-db:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
      };
### Grafana container
      "grafana-${NAME}" = {
        image = "${grafanaIMAGE}:${cfg.grafana.imageVersion}";
        autoStart = true;
        environment = {};
        environmentFiles = [
          # container listens on port 3000
          config.age.secrets."${NAME}GrafanaEnvFile".path
              #  DATABASE_USER=teslamate
              #  DATABASE_PASS=password #insert your secure database password!
              #  DATABASE_NAME=teslamate
              #  DATABASE_HOST=database
        ];
        volumes = [
          "${cfg.grafana.volumeLocation}/teslamate-grafana-data:/var/lib/grafana"
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
        image = "${IMAGE}:${cfg.imageVersion}";
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
        volumes = [
          "${cfg.volumeLocation}/import:/opt/app/import"
        ];
        extraOptions = [
          "--cap-drop=all"
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
      };
    };
    yomaq.pods.tailscaled."TS${NAME}".TSserve = "http://127.0.0.1:3000";
  };
}
