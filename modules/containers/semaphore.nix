{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
 ### Set container name and image
 NAME = "semaphore";
 IMAGE = "docker.io/semaphoreui/semaphore";

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
    agenixSecret = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/${NAME}EnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
 };

 config = mkIf cfg.enable {

    age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeLocation}/etc 0755 4000 4000"
      "d ${cfg.volumeLocation}/var 0755 4000 4000"
      # trying to let it let me use a non-root user
      "d ${cfg.volumeLocation}/tmp 0755 4000 4000"
      ];

    virtualisation.oci-containers.containers = {
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        volumes = [
          "${cfg.volumeLocation}/etc:/etc/semaphore"
          "${cfg.volumeLocation}/var:/var/lib/semaphore"
          "${cfg.volumeLocation}/tmp:/tmp/semaphore/"
        ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
        user = "4000:4000";
        environment = {
          SEMAPHORE_DB_DIALECT = "bolt";
          "PUID" = "4000";
          "PGID" = "4000";          
        };
        environmentFiles = [
          config.age.secrets."${NAME}EnvFile".path
          # SEMAPHORE_ADMIN_PASSWORD = cfg.adminPassword;
          # SEMAPHORE_ADMIN_NAME = cfg.adminName;
          # SEMAPHORE_ADMIN_EMAIL = cfg.adminEmail;
          # SEMAPHORE_ADMIN = cfg.adminName;
          # SEMAPHORE_ACCESS_KEY_ENCRYPTION =
        ];
      };
    };

    yomaq.pods.tailscaled."TS${NAME}" = {
      TSserve = {"/" = "http://127.0.0.1:3000";};
      tags = ["tag:generichttps"];
    };

    yomaq.homepage.groups.services.services = [{
      "${NAME}" = {
        icon = "si-ansible";
        href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
        siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      };
    }];
 };
}
