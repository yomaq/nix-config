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
            imageVersion = lib.mkOption {
              type = lib.types.str;
              default = "latest";
              description = ''
                container image version
              '';
            };
            ### chrome container
            chrome = {
              imageVersion = lib.mkOption {
                type = lib.types.str;
                default = "latest";
                description = ''
                  container image version
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
          image = "${secondIMAGE}:${cfg.chrome.imageVersion}";
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
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
        ### main container
        "${NAME}" = {
          image = "${IMAGE}:${cfg.imageVersion}";
          autoStart = true;
          environment = {
            "PLAYWRIGHT_DRIVER_URL" = "ws://127.0.0.1:3000";
            # "BASE_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          };
          environmentFiles = [ ];
          volumes = [ "${cfg.volumeLocation}/datastore:/datastore" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
      };
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:5000";
        };
        tags = [ "tag:generichttps" ];
      };
      yomaq.homepage.groups.services.services = [
        {
          "${NAME}" = {
            icon = "mdi-bookmark-box";
            href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
            siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          };
        }
      ];
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
  ];
}
