{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "factorio";
  IMAGE = "docker.io/ofsm/ofsm";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.yomaq.impermanence) backup;

  containerOpts =
    { name, ... }:
    let
      startsWith = lib.substring 0 12 name == "factorio";
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
            "FACTORIO_VERSION" = "stable";
          };
          description = ''
            set custom environment variables for the "${NAME}" container
          '';
        };
      };
    };
  mkContainer = name: cfg: {
    image = "docker.io/ofsm/ofsm:latest@sha256:2b031bc1ec51e437a90b24266ce87f82362b4d16670e3804688610b4ac03b608";
    autoStart = true;
    environment = lib.mkMerge [
      cfg.envVariables
      { }
    ];
    volumes = [
      "${cfg.volumeLocation}/factorio/fsm-data:/opt/fsm-data"
      "${cfg.volumeLocation}/factorio/saves:/opt/factorio/saves"
      "${cfg.volumeLocation}/factorio/mods:/opt/factorio/mods"
      "${cfg.volumeLocation}/factorio/config:/opt/factorio/config"
      "${cfg.volumeLocation}/factorio/mod_packs:/opt/fsm/mod_packs"
    ];
    dependsOn = [ "TS${name}" ];
    extraOptions = [
      "--network=container:TS${name}"
    ];
  };
  mkTmpfilesRules = _name: cfg: [
    "d ${cfg.volumeLocation}/factorio/fsm-data 0755 root root"
    "d ${cfg.volumeLocation}/factorio/saves 0755 root root"
    "d ${cfg.volumeLocation}/factorio/mods 0755 root root"
    "d ${cfg.volumeLocation}/factorio/config 0755 root root"
    "d ${cfg.volumeLocation}/factorio/mod_packs 0755 root root"
  ];
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
      tags = [ "tag:factorio" ];
      TSserve = {
        "/" = "http://127.0.0.1:80";
      };
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
