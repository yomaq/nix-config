{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "ollama";
  IMAGE = "docker.io/ollama/ollama";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
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
              default = "${dontBackup}/containers/${NAME}";
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
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/ollama 0755 root root" ];

      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "${IMAGE}:${cfg.imageVersion}";
          autoStart = true;
          environment = {
            "OLLAMA_NUM_PARALLEL" = "1";
          };
          volumes = [ "${cfg.volumeLocation}/ollama:/root/.ollama" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
            "--device=nvidia.com/gpu=all"
          ];
        };
      };

      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:11434";
        };
        tags = [ "tag:ollama-server" ];
      };

      # yomaq.homepage.groups.services.services = [
      #   {
      #     "${NAME}" = {
      #       icon = "si-files";
      #       href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      #       siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      #     };
      #   }
      # ];
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
