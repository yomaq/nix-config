{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "satisfactory";
  IMAGE = "docker.io/wolveix/satisfactory-server";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.yomaq.impermanence) backup;

  containerOpts =
    { name, ... }:
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
    image = "docker.io/wolveix/satisfactory-server:latest@sha256:e103700ae6ae4c50f19dac80eadb2a805c5b885e179ae2a40850e967bf189efd";
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
    dependsOn = [ "TS${name}" ];
    extraOptions = [
      "--network=container:TS${name}"
    ];
  };
  mkTmpfilesRules = _name: cfg: [ "d ${cfg.volumeLocation}/data 0755 4000 4000" ];
  containersList = lib.attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;

in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.pods = {
            "${NAME}" = lib.mkOption {
              default = { };
              type = with lib.types; attrsOf (submodule containerOpts);
              example = { };
              description = lib.mdDoc ''
                ${NAME} Server
              '';
            };
          };
        }
      );
    };
  };
  config = lib.mkIf (cfg != { }) {
    yomaq.pods.tailscaled = lib.genAttrs renameTScontainers (_container: {
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
