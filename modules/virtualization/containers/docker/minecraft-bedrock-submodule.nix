{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "minecraftBedrock";
  IMAGE = "docker.io/itzg/minecraft-bedrock-server";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;

  containerOpts =
    { name, ... }:
    let
      startsWith = lib.substring 0 9 name == "minecraft";
      shortName = if startsWith then lib.substring 9 (-1) name else name;
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
          default = "${backup}/containers/minecraft/bedrock/${name}";
          description = ''
            path to store container volumes
          '';
        };
        imageVersion = lib.mkOption {
          type = lib.types.str;
          default = "latest";
          description = ''
            container image version
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
            "EULA" = "TRUE";
            "gamemode" = "survival";
            "difficulty" = "hard";
            "allow-cheats" = "true";
            "max-players" = "10";
            "view-distance" = "50";
            "tick-distance" = "4";
            "TEXTUREPACK_REQUIRED" = "true";
          };
          description = ''
            set custom environment variables for the bedrock container
          '';
        };
      };
    };
  mkContainer = name: cfg: {
    image = "${IMAGE}:${cfg.imageVersion}";
    autoStart = true;
    environment = lib.mkMerge [
      cfg.envVariables
      { "SERVER_NAME" = "${cfg.serverName}"; }
    ];
    volumes = [ "${cfg.volumeLocation}/data:/data" ];
    extraOptions = [
      "--pull=always"
      "--network=container:TS${name}"
    ];
    user = "4000:4000";
  };
  mkTmpfilesRules = _name: cfg: [ "d ${cfg.volumeLocation}/data 0755 4000 4000" ];
  containersList = lib.attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;

  homepageServices = name: [
    {
      "${name}" = {
        icon = "si-minecraft";
        href = "https://${hostName}-${name}.${tailnetName}.ts.net";
        widget = {
          type = "gamedig";
          serverType = "minecraftbe";
          url = "udp://${hostName}-${name}.${tailnetName}.ts.net:19132";
          fields = [
            "status"
            "players"
            "ping"
          ];
        };
      };
    }
  ];
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.pods = {
            minecraftBedrock = lib.mkOption {
              default = { };
              type = with lib.types; attrsOf (submodule containerOpts);
              example = { };
              description = lib.mdDoc ''
                Minecraft Bedrock Server
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
        tags = [ "tag:minecraft" ];
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
    (lib.mkIf config.yomaq.homepage.enable {
      # Layout configuration for Minecraft tab
      yomaq.homepage.settingsLayout.minecraft = {
        tab = "Services";
        style = "column";
      };

      # Service widgets for Minecraft Bedrock servers
      yomaq.homepage.services.minecraft =
        lib.foldl
          (
            acc: hostName:
            let
              hostConfig = config.inventory.hosts.${hostName};
              bedrockServers = lib.filterAttrs (name: value: value.enable or false) (
                hostConfig.pods.minecraftBedrock or { }
              );
            in
            acc
            // (lib.mapAttrs (serverName: serverConfig: {
              icon = "si-minecraft";
              href = "https://${hostName}-${serverName}.${tailnetName}.ts.net";
              widget = {
                type = "gamedig";
                serverType = "minecraftbe";
                url = "udp://${hostName}-${serverName}.${tailnetName}.ts.net:19132";
                fields = [
                  "status"
                  "players"
                  "ping"
                ];
              };
            }) bedrockServers)
          )
          { }
          (
            lib.filter (hostName: (config.inventory.hosts.${hostName}.pods.minecraftBedrock or { }) != { }) (
              builtins.attrNames config.inventory.hosts
            )
          );
    })
  ];
}
