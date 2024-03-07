{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "minecraftBedrock";
  IMAGE = "docker.io/itzg/minecraft-bedrock-server";

  cfg = config.yomaq.pods.minecraftBedrock;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;

  containerOpts = { name, config, ... }: 
  let
    startsWith = substring 0 9 name == "minecraft";
    shortName = if startsWith then substring 9 (-1) name else name;
  in
  {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          enable custom ${NAME} container module
        '';
      };
      volumeLocation = mkOption {
        type = types.str;
        default = "${backup}/containers/minecraft/bedrock/${name}";
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
      serverName = mkOption {
        type = types.str;
        default = "${shortName}";
        description = ''
          serverName
        '';
      };
      envVariables = mkOption {
        type = types.attrsOf types.str;
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
    volumes = ["${cfg.volumeLocation}/data:/data"];
    extraOptions = [
      "--pull=always"
      "--network=container:TS${name}"
    ];
    user = "4000:4000";
  };
  mkTmpfilesRules = name: cfg: [
    "d ${cfg.volumeLocation}/data 0755 4000 4000"
  ];
  # this is written oddly, I dont know how to write it differently yet
  mkTailscaledContainer = name: cfg: {enable = true;};
  mapToTailscaled = lib.mapAttrs mkTailscaledContainer config.yomaq.pods.minecraftBedrock;
  formatToTailscaled = lib.foldl' (acc: a: acc // a) {} (lib.attrValues mapToTailscaled);
in
{
  options.yomaq.pods = {
    minecraftBedrock = mkOption {
      default = {};
      type = with types; attrsOf (submodule containerOpts);
      example = {};
      description = lib.mdDoc ''
        Minecraft Bedrock Server
      '';
    };
  };
  config = mkIf (cfg != {}) {
    yomaq.pods.tailscaled = lib.mapAttrs mkTailscaledContainer formatToTailscaled;
    systemd.tmpfiles.rules = lib.flatten ( lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) config.yomaq.pods.minecraftBedrock);
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.yomaq.pods.minecraftBedrock;
  };
}