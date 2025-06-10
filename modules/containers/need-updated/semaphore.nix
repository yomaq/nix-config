{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  ### Set container name and image
  NAME = "semaphore";
  IMAGE = "docker.io/semaphoreui/semaphore";
  DBIMAGE = "docker.io/mysql";

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
      default = "latest";
      description = ''
        container image version
      '';
    };
    imageVersionDB = mkOption {
      type = types.str;
      default = "8.0";
      description = ''
        container image version
      '';
    };
    agenixSecret = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/${NAME}EnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
    agenixSecretDB = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/${NAME}DBEnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
  };

  config = mkIf cfg.enable {

    age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
    age.secrets."${NAME}DBEnvFile".file = cfg.agenixSecretDB;

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeLocation}/var 0755 4000 4000"
    ];

    virtualisation.oci-containers.containers = {
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        volumes = [ ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
        environment = {
          SEMAPHORE_DB_USER = "semaphore";
          SEMAPHORE_DB_HOST = "127.0.0.1";
          SEMAPHORE_DB_PORT = "3306";
          SEMAPHORE_DB_DIALECT = "mysql";
          SEMAPHORE_DB = "semaphore";
        };
        environmentFiles = [
          config.age.secrets."${NAME}EnvFile".path
          # SEMAPHORE_ADMIN_PASSWORD = cfg.adminPassword;
          # SEMAPHORE_ADMIN_NAME = cfg.adminName;
          # SEMAPHORE_ADMIN_EMAIL = cfg.adminEmail;
          # SEMAPHORE_ADMIN = cfg.adminName;
          # SEMAPHORE_ACCESS_KEY_ENCRYPTION =
          # SEMAPHORE_DB_PASS =
        ];
      };
      "${NAME}DB" = {
        image = "${DBIMAGE}:${cfg.imageVersionDB}";
        autoStart = true;
        volumes = [
          "${cfg.volumeLocation}/var:/var/lib/mysql"
        ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
        environmentFiles = [
          config.age.secrets."${NAME}DBEnvFile".path
          #MYSQL_RANDOM_ROOT_PASSWORD='yes'
          #MYSQL_DATABASE=semaphore
          #MYSQL_USER=semaphore
          #MYSQL_PASSWORD=
        ];
        user = "4000:4000";
      };
    };

    yomaq.pods.tailscaled."TS${NAME}" = {
      TSserve = {
        "/" = "http://127.0.0.1:3000";
      };
      tags = [ "tag:generichttps" ];
    };

    yomaq.homepage.groups.services.services = [
      {
        "${NAME}" = {
          icon = "si-ansible";
          href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
        };
      }
    ];
  };
}
