{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "palworld";
  IMAGE = "docker.io/jammsen/palworld-dedicated-server";
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
          "ALWAYS_UPDATE_ON_START" = "true";
          "MULTITHREAD_ENABLED" = "true";
          "COMMUNITY_SERVER" = "true";
          "BACKUP_ENABLED" = "true";
          "BACKUP_CRON_EXPRESSION" = "0 * * * *";
          "STEAMCMD_VALIDATE_FILES" = "true";
          "SERVER_SETTINGS_MODE" = "auto";
          "NETSERVERMAXTICKRATE" = "120";
          "DIFFICULTY" = "Difficult";
          "DAYTIME_SPEEDRATE" = "1.000000";
          "NIGHTTIME_SPEEDRATE" = "1.000000";
          "EXP_RATE" = "2.000000";
          "PAL_CAPTURE_RATE" = "1.000000";
          "PAL_SPAWN_NUM_RATE" = "1.000000";
          "PAL_DAMAGE_RATE_ATTACK" = "1.000000";
          "PAL_DAMAGE_RATE_DEFENSE" = "1.000000";
          "PLAYER_DAMAGE_RATE_ATTACK" = "1.000000";
          "PLAYER_DAMAGE_RATE_DEFENSE" = "1.000000";
          "PLAYER_STOMACH_DECREASE_RATE" = "1.000000";
          "PLAYER_STAMINA_DECREACE_RATE" = "1.000000";
          "PLAYER_AUTO_HP_REGENE_RATE" = "1.000000";
          "PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP" = "1.000000";
          "PAL_STOMACH_DECREACE_RATE" = "1.000000";
          "PAL_STAMINA_DECREACE_RATE" = "1.000000";
          "PAL_AUTO_HP_REGENE_RATE" = "1.000000";
          "PAL_AUTO_HP_REGENE_RATE_IN_SLEEP" = "1.000000";
          "BUILD_OBJECT_DAMAGE_RATE" = "1.000000";
          "BUILD_OBJECT_DETERIORATION_DAMAGE_RATE" = "1.000000";
          "COLLECTION_DROP_RATE" = "1.000000";
          "COLLECTION_OBJECT_HP_RATE" = "1.000000";
          "COLLECTION_OBJECT_RESPAWN_SPEED_RATE" = "1.000000";
          "ENEMY_DROP_ITEM_RATE" = "1.000000";
          "DEATH_PENALTY" = "Item";
          "ENABLE_PLAYER_TO_PLAYER_DAMAGE" = "false";
          "ENABLE_FRIENDLY_FIRE" = "false";
          "ENABLE_INVADER_ENEMY" = "true";
          "ACTIVE_UNKO" = "false";
          "ENABLE_AIM_ASSIST_PAD" = "true";
          "ENABLE_AIM_ASSIST_KEYBOARD" = "false";
          "DROP_ITEM_MAX_NUM" = "3000";
          "DROP_ITEM_MAX_NUM_UNKO" = "100";
          "BASE_CAMP_MAX_NUM" = "128";
          "BASE_CAMP_WORKER_MAXNUM" = "15";
          "DROP_ITEM_ALIVE_MAX_HOURS" = "1.000000";
          "AUTO_RESET_GUILD_NO_ONLINE_PLAYERS" = "false";
          "AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS" = "72.000000";
          "GUILD_PLAYER_MAX_NUM" = "20";
          "PAL_EGG_DEFAULT_HATCHING_TIME" = "72.000000";
          "WORK_SPEED_RATE" = "1.000000";
          "IS_MULTIPLAY" = "true";
          "IS_PVP" = "true";
          "CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP" = "false";
          "ENABLE_NON_LOGIN_PENALTY" = "true";
          "ENABLE_FAST_TRAVEL" = "true";
          "IS_START_LOCATION_SELECT_BY_MAP" = "true";
          "EXIST_PLAYER_AFTER_LOGOUT" = "false";
          "ENABLE_DEFENSE_OTHER_GUILD_PLAYER" = "false";
          "COOP_PLAYER_MAX_NUM" = "6";
          "MAX_PLAYERS" = "6";
          "PUBLIC_PORT" = "8211";
        };
        environmentFiles = [
          config.age.secrets."${NAME}EnvFile".path
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