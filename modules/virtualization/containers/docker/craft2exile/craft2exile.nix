{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  ### Set container name and image
  NAME = "craft2exile";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;

  dynmapRenderScript = pkgs.writeTextFile {
    name = "dynmap-render.sh";
    executable = true;
    text = ''
      #!/bin/sh
      read -p "World [world]: " world
      world=''${world:-world}

      read -p "Radius in blocks [4096]: " radius
      radius=''${radius:-4096}

      rcon-cli "dynmap radiusrender $world 0 0 $radius"
    '';
  };
  # dynmap config file
  dynmapConfig = ./dynmap-configuration.txt;
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
            # mincraft env 
            env = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = {
                "EULA" = "TRUE";
                "USE_MEOWICE_FLAGS" = "true";

                "DIFFICULTY" = "hard";
                "ENABLE_COMMAND_BLOCK" = "true";
                "SNOOPER_ENABLED" = "false";
                "SEED" = "2423947040338671082";
                "ALLOW_FLIGHT" = "true";
                "SERVER_NAME" = "craft2exile";

                "TYPE" = "AUTO_CURSEFORGE";
                "MEMORY" = "16G";
                "MAX_TICK_TIME" = "-1";
                "RCON_PASSWORD" = "minecraft";

                "CF_SLUG" = "craft-to-exile-2";
                "CF_FILE_ID" = "7192795";
                "SERVER_PORT" = "19132";


                "CF_EXCLUDE_MODS" = '' 1023333, 222378'';

                "CF_FORCE_INCLUDE_MODS" = "1187311,1207903";

                # Dynmap-Forge/Fabric
                "CURSEFORGE_FILES" = ''59433'';
                
                # "CF_FORCE_SYNCHRONIZE" = "true";

                "RCON_CMDS_STARTUP" = ''
                  dynmap updaterender world 0 0 
                '';
                "RCON_CMDS_FIRST_CONNECT" = ''
                  dynmap cancelrender world
                '';
                "RCON_CMDS_LAST_DISCONNECT" = ''
                  dynmap updaterender world 0 0
                '';
              };
              description = ''
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      ### agenix secret for CF_API_KEY
      age.secrets."curseForgeApi".file = inputs.self + /secrets/curseForgeApi.age;
      # create folders
      systemd.tmpfiles.rules = [
        "d ${cfg.volumeLocation}/data 0755 4000 4000"
        "d ${cfg.volumeLocation}/data/dynmap 0755 4000 4000"
        "d ${cfg.volumeLocation}/data/config 0755 4000 4000"
        "d ${cfg.volumeLocation}/data/yomaq 0755 4000 4000"
        "d ${cfg.volumeLocation}/backups 0755 4000 4000"
      ];

      virtualisation.oci-containers.containers = {
        # minecraft container itself
        "${NAME}" = {
          image = "docker.io/itzg/minecraft-server:latest";
          autoStart = true;
          environment = cfg.env;
          environmentFiles = [ config.age.secrets."curseForgeApi".path ];
          volumes = [
            "${cfg.volumeLocation}/data:/data"
            "${dynmapConfig}:/data/dynmap/configuration.txt:ro"
            "${dynmapRenderScript}:/data/yomaq/dynmap-render.sh:ro"
          ];
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
          user = "4000:4000";
        };

        # auto backup container
        "${NAME}-backup" = {
          image = "docker.io/itzg/mc-backup:latest";
          autoStart = true;
          environment = {
            BACKUP_INTERVAL = "2h";
            PRUNE_BACKUPS_DAYS = "14";
            RCON_HOST = "127.0.0.1";
            RCON_PORT = "25575";
            RCON_PASSWORD = "minecraft";
            INITIAL_DELAY = "5m";
          };
          volumes = [
            "${cfg.volumeLocation}/data:/data:ro"
            "${cfg.volumeLocation}/backups:/backups"
          ];
          dependsOn = [ "${NAME}" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
          user = "4000:4000";
        };
      };

      # auto restart container
      systemd.services."docker-${NAME}" = {
        serviceConfig = {
          RuntimeMaxSec = "6h";
        };
      };

      # networking
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:8123";
        };
        tags = [ "tag:lockdown" ];
      };
      #monitoring
      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
      yomaq.monitorServices.services."docker-${NAME}-backup".priority = "medium";
    })
  ];
}
