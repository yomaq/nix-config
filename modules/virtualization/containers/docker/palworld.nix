{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "palworld";
  IMAGE = "docker.io/thijsvanloef/palworld-server-docker";
  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;

  containerOpts =
    { name, ... }:
    let
      startsWith = lib.substring 0 8 name == "palworld";
      shortName = if startsWith then lib.substring 8 (-1) name else name;
    in
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            enable custom ${NAME} container module
          '';
        };
        volumeLocation = lib.mkOption {
          type = lib.types.str;
          default = "${backup}/containers/palworld/${name}";
          description = ''
            path to store container volumes
          '';
        };
        serverName = lib.mkOption {
          type = lib.types.str;
          default = "${shortName}";
          description = ''
            serverName
          '';
        };
        envVariables = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            PUID = "1000";
            PGID = "1000";
            PORT = "8211";
            PLAYERS = "6";
            SERVER_PASSWORD = "password";
            MULTITHREADING = "true";
            RCON_ENABLED = "true";
            RCON_PORT = "25575";
            TZ = "UTC";
            ADMIN_PASSWORD = "admin";
            COMMUNITY = "false";
            DEATH_PENALTY = "Item";
            EXP_RATE = "1";
            DIFFICULTY = "difficult";
            bAllowGlobalPalboxImport = "false";
            bAllowGlobalPalboxExport = "true";
          };
          description = ''
            set custom environment variables for the palworld container
          '';
        };
      };
    };

  mkContainer = name: cfg: {
    image = "docker.io/thijsvanloef/palworld-server-docker:latest@sha256:b6b6490e7365a819f88c46f02513f8d6acd08fd4b1c01f837de164efc0b2ea79";
    autoStart = true;
    environment = lib.mkMerge [
      cfg.envVariables
      { "SERVER_NAME" = "${cfg.serverName}"; }
    ];
    volumes = [ "${cfg.volumeLocation}/palworld:/palworld" ];
    dependsOn = [ "TS${name}" ];
    extraOptions = [
      "--pull=always"
      "--cap-add=sys_nice"
      "--network=container:TS${name}"
    ];
    user = "1000:1000";
  };

  mkTmpfilesRules = _name: cfg: [ "d ${cfg.volumeLocation}/palworld 0766 1000 1000" ];

  containersList = lib.attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.pods = {
            palworld = lib.mkOption {
              default = { };
              type = with lib.types; attrsOf (submodule containerOpts);
              example = { };
              description = lib.mdDoc ''
                Palworld Server
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg != { }) {
      yomaq.pods.tailscaled = lib.genAttrs renameTScontainers (_container: {
        tags = [ "tag:palworld" ];
      });
      systemd.tmpfiles.rules = lib.flatten (lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) cfg);
      virtualisation.oci-containers.containers = lib.mapAttrs mkContainer cfg;
      yomaq.monitorServices.services = lib.mkMerge (
        lib.mapAttrsToList (name: _: {
          "docker-${name}" = {
            priority = "medium";
          };
        }) cfg
      );
    })
  ];
}
