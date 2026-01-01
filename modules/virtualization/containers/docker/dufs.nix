{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "dufs";
  IMAGE = "docker.io/sigoden/dufs";

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
      systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/data 0755 4000 4000" ];
      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "docker.io/sigoden/dufs:latest";
          autoStart = true;
          volumes = [ "${cfg.volumeLocation}/data:/data" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
          user = "4000:4000";
          cmd = [
            "/data"
            "--allow-upload"
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
              icon = "si-files";
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
