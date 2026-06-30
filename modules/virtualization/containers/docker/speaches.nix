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
          image = "ghcr.io/remsky/kokoro-fastapi-gpu:v0.5.0@sha256:63176e12e476470f020e29dfb3203bac249fa66c8fdf95e44b7482546eb4e974";
          autoStart = true;
          environment = cfg.env;
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
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
    #             "failure-threshold" = 3;
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
