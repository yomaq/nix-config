{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "necesse";
  IMAGE = "docker.io/brammys/necesse-server";
  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;
  containerOpts =
    { name, ... }:
    let
      startsWith = lib.substring 0 7 name == "necesse";
      shortName = if startsWith then lib.substring 7 (-1) name else name;
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
          default = "${backup}/containers/necesse/${name}";
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
            "PAUSE" = "1";
          };
          description = ''
            set custom environment variables for the necesse container
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
    volumes = [ "${cfg.volumeLocation}/saves:/necesse/saves" ];
    extraOptions = [
      "--pull=always"
      "--network=container:TS${name}"
    ];
  };
  mkTmpfilesRules = _name: cfg: [ "d ${cfg.volumeLocation}/saves 0755 root root" ];
  containersList = lib.attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.pods = {
            necesse = lib.mkOption {
              default = { };
              type = with lib.types; attrsOf (submodule containerOpts);
              example = { };
              description = lib.mdDoc ''
                Necesse Game Server
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
        tags = [ "tag:satisfactory" ];
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
