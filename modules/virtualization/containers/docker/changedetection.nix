{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "changedetection";
  IMAGE = "ghcr.io/dgtlmoon/changedetection.io";
  secondIMAGE = "docker.io/browserless/chrome";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
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
            volumeLocation = lib.mkOption {
              type = lib.types.str;
              default = "${backup}/containers/${NAME}";
              description = ''
                path to store container volumes
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # ### agenix secrets for container
      # age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
      # age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;

      systemd.tmpfiles.rules = [
        # main container
        "d ${cfg.volumeLocation}/datastore 0755 4000 4000"
      ];
      virtualisation.oci-containers.containers = {
        ### DB container
        "chrome${NAME}" = {
          image = "docker.io/browserless/chrome:latest@sha256:57d19e414d9fe4ae9d2ab12ba768c97f38d51246c5b31af55a009205c136012f";
          autoStart = true;
          environment = {
            "SCREEN_WIDTH" = "1920";
            "SCREEN_HEIGHT" = "1024";
            "SCREEN_DEPTH" = "16";
            "ENABLE_DEBUGGER" = "false";
            "PREBOOT_CHROME" = "true";
            "CONNECTION_TIMEOUT" = "300000";
            "MAX_CONCURRENT_SESSIONS" = "10";
            "CHROME_REFRESH_TIME " = "600000";
            "DEFAULT_BLOCK_ADS" = "true";
            "DEFAULT_STEALTH" = "true";
            # Ignore HTTPS errors, like for self-signed certs
            "DEFAULT_IGNORE_HTTPS_ERRORS" = "true";
          };
          environmentFiles = [ ];
          volumes = [ ];
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
            "--network=container:TS${NAME}"
          ];
        };
        ### main container
        "${NAME}" = {
          image = "ghcr.io/dgtlmoon/changedetection.io:latest@sha256:e95931043d68da46e90498ce74ad317b392caade07186dc06bdfa1710901bf90";
          autoStart = true;
          environment = {
            "PLAYWRIGHT_DRIVER_URL" = "ws://127.0.0.1:3000";
            # "BASE_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          };
          environmentFiles = [ ];
          volumes = [ "${cfg.volumeLocation}/datastore:/datastore" ];
          dependsOn = [
            "TS${NAME}"
            "chrome${NAME}"
          ];
          extraOptions = [
            "--network=container:TS${NAME}"
          ];
        };
      };
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:5000";
        };
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
              icon = "mdi-bookmark-box";
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
