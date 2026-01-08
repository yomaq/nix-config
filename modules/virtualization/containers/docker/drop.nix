{
  config,
  lib,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "drop";
  IMAGE = "ghcr.io/drop-oss/drop";
  dbIMAGE = "docker.io/postgres";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) backupStorage;
  inherit (config.yomaq.tailscale) tailnetName;
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
            agenixSecret = lib.mkOption {
              type = lib.types.path;
              default = (inputs.self + /secrets/${NAME}EnvFile.age);
              description = ''
                path to agenix secret file
              '';
            };
            volumeLocation = lib.mkOption {
              type = lib.types.str;
              default = "${backup}/containers/${NAME}";
              description = ''
                path to store container volumes
              '';
            };
            libraryLocation = lib.mkOption {
              type = lib.types.str;
              default = "${backupStorage}/containers/${NAME}/library";
              description = ''
                path to store game library files
              '';
            };
            ### database container
            database = {
              agenixSecret = lib.mkOption {
                type = lib.types.path;
                default = (inputs.self + /secrets/${NAME}DBEnvFile.age);
                description = ''
                  path to agenix secret file
                '';
              };
              volumeLocation = lib.mkOption {
                type = lib.types.str;
                default = "${backup}/containers/${NAME}";
                description = ''
                  path to store container volumes
                '';
              };
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      ### agenix secrets for container
      age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
      age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;

      systemd.tmpfiles.rules = [
        # main container
        "d ${cfg.volumeLocation}/data 0755 root root"
        "d ${cfg.libraryLocation} 0755 root root"
        # database container
        "d ${cfg.database.volumeLocation}/db 0755 root root"
      ];
      virtualisation.oci-containers.containers = {
        ### DB container
        "DB${NAME}" = {
          image = "docker.io/postgres:14-alpine@sha256:14f02666642586a64d6fae8ef42d479fd76456a77c73ae8a626b8fe323b76d22";
          autoStart = true;
          environmentFiles = [
            config.age.secrets."${NAME}DBEnvFile".path
            #  POSTGRES_PASSWORD=drop
            #  POSTGRES_USER=drop
            #  POSTGRES_DB=drop
          ];
          volumes = [ "${cfg.database.volumeLocation}/db:/var/lib/postgresql/data" ];
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
            "--health-cmd=pg_isready -U drop"
            "--health-interval=30s"
          ];
        };
        ### main container
        "${NAME}" = {
          image = "ghcr.io/drop-oss/drop:latest@sha256:2995f0b75ac3a6bc4d33b584f80882c3415f8bd9182c264378e3829b259b0bd4";
          autoStart = true;
          dependsOn = [
            "TS${NAME}"
            "DB${NAME}"
          ];
          environment = {
            "EXTERNAL_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          };
          environmentFiles = [
            config.age.secrets."${NAME}EnvFile".path
            #  DATABASE_URL=postgres://drop:drop@127.0.0.1:5432/drop
          ];
          volumes = [
            "${cfg.libraryLocation}:/library"
            "${cfg.volumeLocation}/data:/data"
          ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
      };
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:3000";
        };
        tags = [ "tag:lockdown" ];
      };
      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
    })
    (lib.mkIf config.yomaq.gatus.enable {
      yomaq.gatus.endpoints =
        map
          (host: {
            name = "${host}-${NAME}";
            group = "webapps";
            url = "https://${host}-${NAME}.${config.yomaq.tailscale.tailnetName}.ts.net";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [
              {
                type = "ntfy";
                failureThreshold = 3;
                description = "healthcheck failed";
              }
            ];
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.pods."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          );
    })
    (lib.mkIf config.yomaq.homepage.enable {
      yomaq.homepage.groups.services = builtins.listToAttrs (
        map
          (host: {
            name = "${NAME} - ${host}";
            value = {
              icon = "mdi-gamepad-variant";
              href = "https://${host}-${NAME}.${tailnetName}.ts.net/";
              siteMonitor = "https://${host}-${NAME}.${tailnetName}.ts.net/";
            };
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.pods."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          )
      );
    })
  ];
}
