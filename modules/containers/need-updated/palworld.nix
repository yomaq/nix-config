{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "palworld";
  IMAGE = "docker.io/thijsvanloef/palworld-server-docker";
  tailscaleIMAGE = "ghcr.io/tailscale/tailscale";


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
    # agenixSecret = mkOption {
    #   type = types.path;
    #   default = (inputs.self + /secrets/${NAME}EnvFile.age);
    #   description = ''
    #     path to agenix secret file
    #   '';
    # };
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
    # age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
    age.secrets."tailscaleEnvFile".file = cfg.tailscale.agenixSecret;

  # make the directories where the volumes are stored
    systemd.tmpfiles.rules = [
      # main container
      "d ${cfg.volumeLocation}/palworld 0766 root root"
      # # tailscale
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
          "--pull=always"
          "--network=host"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
        ];
      };


### main container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
            PUID = "1000";
            PGID = "1000";
            PORT = "8211"; # Optional but recommended
            PLAYERS = "6"; # Optional but recommended
            SERVER_PASSWORD = ""; # Optional but recommended
            MULTITHREADING = "true";
            RCON_ENABLED = "true";
            RCON_PORT = "25575";
            TZ = "UTC";
            ADMIN_PASSWORD = "adminPasswordHereShhhhh";
            COMMUNITY = "false"; # Enable this if you want your server to show up in the community servers tab, USE WITH SERVER_PASSWORD!
            SERVER_NAME = "World of Pals";
            SERVER_DESCRIPTION = "Awesome World of Pal";
            # server settings
            "DEATH_PENALTY" = "Item";
            "EXP_RATE" = "2";
            "DIFFICULTY" = "diffucult";
        };
        environmentFiles = [
          # config.age.secrets."${NAME}EnvFile".path
        ];
        volumes = [
          "${cfg.volumeLocation}/palworld:/palworld"
        ];
        extraOptions = [
          "--pull=always"
          "--cap-add=sys_nice"
          "--network=container:TS${NAME}"
        ];
      };
    };
  };
}