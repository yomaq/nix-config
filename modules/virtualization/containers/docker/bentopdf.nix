{
  config,
  lib,
  ...
}:
let
  ### Set container name
  NAME = "bentopdf";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
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
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "bentopdf/bentopdf-simple:latest@sha256:ed728002dede243e99da3b5f66a88ef4aa842962d5fc1313a75ab841cc9af237";
          autoStart = true;
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
      };

      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:8080";
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
              icon = "mdi-file-pdf-box";
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
