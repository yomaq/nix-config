{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "speaches";
  IMAGE = "ghcr.io/remsky/kokoro-fastapi-gpu";

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
            env = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = {
              };
              description = ''
                env options
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
          image = "ghcr.io/remsky/kokoro-fastapi-gpu:v0.2.4@sha256:79d81c41d8883611291c5785e47db2ba00765e9b89dd59de05d9f28e1945f905";
          autoStart = true;
          environment = cfg.env;
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
            "--device=nvidia.com/gpu=all"
          ];
        };
      };

      yomaq.pods.tailscaled."TS${NAME}" = {
        enable = true;
        # TSserve = {
        #   "/" = "http://127.0.0.1:8000";
        # };
        tags = [
          "tag:speaches"
        ];
      };

      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
    })
    # (lib.mkIf config.yomaq.gatus.enable {
    #   yomaq.gatus.endpoints =
    #     map
    #       (host: {
    #         name = "${host}-${NAME}";
    #         group = "webapps";
    #         url = "https://${host}-${NAME}.${config.yomaq.tailscale.tailnetName}.ts.net";
    #         interval = "5m";
    #         conditions = [ "[STATUS] == 200" ];
    #         alerts = [
    #           {
    #             type = "ntfy";
    #             failureThreshold = 3;
    #             description = "healthcheck failed";
    #           }
    #         ];
    #       })
    #       (
    #         builtins.filter (host: config.inventory.hosts.${host}.pods."${NAME}".enable or false) (
    #           builtins.attrNames config.inventory.hosts
    #         )
    #       );
    # })
  ];
}
