
{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "nextcloud";
  IMAGE = "docker.io/nextcloud";
  tailscaleIMAGE = "ghcr.io/tailscale/tailscale";
  dbIMAGE = "docker.io/mariadb";


  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
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
      default = "stable-fpm";
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
        default = "${backup}/containers/${NAME}DB";
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
### tailscale container
    tailscale = {
      agenixSecret = mkOption {
        type = types.path;
        default = (inputs.self + /secrets/tailscaleEnvFile.age);
        description = ''
          path to agenix secret file
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "latest";
        description = ''
          container image version
        '';
      };
      TSargs = mkOption {
        type = types.str;
        default = "--ssh=true";
        description = ''
          TS_Extra_ARGS env var
        '';
      };
      TShostname = mkOption {
        type = types.str;
        default = "${hostName}-${NAME}";
        description = ''
          TS_HOSTNAME env var
        '';
      };
      volumeLocation = mkOption {
        type = types.str;
        default = "${dontBackup}/containers/${NAME}";
        description = ''
          path to store container volumes
        '';
      };
    };
  };




  config = mkIf cfg.enable {
    ### agenix secrets for container
    age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
    # age.secrets."tailscaleEnvFile".file = cfg.tailscale.agenixSecret;
    age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;

    systemd.tmpfiles.rules = [
      # main container
      "d ${cfg.volumeLocation}/data 0755 root root"
      "d ${cfg.volumeLocation}/var-www-html 0755 root root"
      # database container
      "d ${cfg.database.volumeLocation}/var-lib-mysql 0755 root root"
    ];
    virtualisation.oci-containers.containers = {
### DB container
      "DB${NAME}" = {
        image = "${dbIMAGE}:${cfg.database.imageVersion}";
        autoStart = true;
        cmd = ["--transaction-isolation=READ-COMMITTED" "--log-bin=binlog" "--binlog-format=ROW"];
        environment = {
        };
        environmentFiles = [
          config.age.secrets."${NAME}DBEnvFile".path
              #  MYSQL_ROOT_PASSWORD=
              #  MYSQL_PASSWORD=
              #  MYSQL_DATABASE=nextcloud
              #  MYSQL_USER=nextcloud
        ];
        volumes = [
          "${cfg.database.volumeLocation}/var-lib-mysql:/var/lib/mysql"
        ];
        extraOptions = [
          "--pull=always"
        ];
      };
### main container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
        };
        environmentFiles = [
          config.age.secrets."${NAME}EnvFile".path
              #  MYSQL_PASSWORD=
              #  MYSQL_DATABASE=nextcloud
              #  MYSQL_USER=nextcloud
              #  MYSQL_HOST=db
        ];
        volumes = [
          "${cfg.volumeLocation}/var-www-html:/var/www/html"
          "${cfg.volumeLocation}/data:/data"
        ];
        extraOptions = [
          "--pull=always"
          # "--link=DB${NAME}:DB${NAME}"
          "--network=container:TS${NAME}"
        ];
      };
    };
    yomaq.pods.tailscaled."TS${NAME}" = {
      enable = true;
      TSserve = "http://127.0.0.1:80";
    };
  };
}