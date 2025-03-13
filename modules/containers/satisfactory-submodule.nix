{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "satisfactory";
  IMAGE = "docker.io/wolveix/satisfactory-server";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;

  containerOpts =
    { name, config, ... }:
    let
      startsWith = lib.substring 0 12 name == "satisfactory";
      shortName = if startsWith then lib.substring 12 (-1) name else name;
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
          default = "${backup}/containers/${NAME}/${shortName}";
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
        envVariables = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            "MAXPLAYERS" = "4";
            "STEAMBETA" = "false";
          };
          description = ''
            set custom environment variables for the "${NAME}" container
          '';
        };
      };
    };
  mkContainer = name: cfg: {
    image = "${IMAGE}:${cfg.imageVersion}";
    autoStart = true;
    environment = lib.mkMerge [
      cfg.envVariables
      { 
        "PGID" = "4000";
        "PUID" = "4000";
        "rootless" = "false";
      }
    ];
    volumes = [ "${cfg.volumeLocation}/data:/config" ];
    extraOptions = [
      "--pull=always"
      "--network=container:TS${name}"
    ];
  };
  mkTmpfilesRules = name: cfg: [ "d ${cfg.volumeLocation}/data 0755 4000 4000" ];
  containersList = lib.attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;

in
{
  options.yomaq.pods = {
    "${NAME}" = lib.mkOption {
      default = { };
      type = with lib.types; attrsOf (submodule containerOpts);
      example = { };
      description = lib.mdDoc ''
        ${NAME} Server
      '';
    };
  };
  config = lib.mkIf (cfg != { }) {
    yomaq.pods.tailscaled = lib.genAttrs renameTScontainers (container: {
      tags = [ "tag:satisfactory" ];
    });
    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) config.yomaq.pods.${NAME}
    );
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.yomaq.pods.${NAME};

    yomaq.monitorServices.services = lib.mkMerge (
      lib.mapAttrsToList (name: _: {
        "docker-${name}" = {
          priority = "medium";
        };
      }) cfg
    );

  };
}
