{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "minecraft";
  IMAGE = "docker.io/nextcloud";
  tailscaleIMAGE = "ghcr.io/tailscale/tailscale";
  dbIMAGE = "docker.io/mariadb";


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
    age.secrets."tailscaleEnvFile".file = cfg.tailscale.agenixSecret;
    age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;

  # make the directories where the volumes are stored
  # it says "tmpfiles" but we don't add rules to remove the tmp file, so its... not tmp?
  # https://discourse.nixos.org/t/creating-directories-and-files-declararively/9349
  # storing volumes in the nix directory because we assume impermanance is wiping root
    systemd.tmpfiles.rules = [
      # main container
      "d ${cfg.volumeLocation}/data 0755 root root"
      # tailscale
      "d ${cfg.tailscale.volumeLocation}/TSdata-lib 0755 root root"
      "d ${cfg.tailscale.volumeLocation}/TSdev-net-tun 0755 root root"
    ];


    virtualisation.oci-containers.containers = {
### tailscale container
      "TS${NAME}" = {
        image = "${tailscaleIMAGE}:${cfg.tailscale.imageVersion}";
        autoStart = true;
        environment = {
        "TS_HOSTNAME" =cfg.tailscale.TShostname;
        "TS_STATE_DIR"= "/var/lib/tailscale";
        "TS_EXTRA_ARGS" = cfg.tailscale.TSargs;
        "TS_ACCEPT_DNS" = "true";
        };
        environmentFiles = [
          # need to set "TS_AUTHKEY=key" in agenix and import here
          config.age.secrets."tailscaleEnvFile".path
        ];
        volumes = [
          "${cfg.tailscale.volumeLocation}/TSdata-lib:/var/lib"
          "${cfg.tailscale.volumeLocation}/TSdev-net-tun:/dev/net/tun"
        ];
        extraOptions = [
          "--pull=newer"
          "--network=host"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
        ];
      };


### DB container
      "DB${NAME}" = {
        image = "${dbIMAGE}:${cfg.database.imageVersion}";
        autoStart = true;
        cmd = ["--transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW"];
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
          "--pull=newer"
          "--pod ${NAME}"
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
          "--pull=newer"
          "--pod ${NAME}"
          "--network=container:TS${NAME}"
        ];
      };
    };
  };
}