{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "speaches";
  IMAGE = "ghcr.io/remsky/kokoro-fastapi-gpu";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;
in
{
  options.yomaq.pods.${NAME} = {
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
    imageVersion = lib.mkOption {
      type = lib.types.str;
      default = "v0.2.1";
      description = ''
        container image version
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "${IMAGE}:${cfg.imageVersion}";
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

      # yomaq.homepage.groups.services.services = [
      #   {
      #     "${NAME}" = {
      #       icon = "si-ollama";
      #       href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      #       siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      #     };
      #   }
      # ];

      yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
    })
    (lib.mkIf config.yomaq.gatus.enable {
      # Add dufs to the list of services to monitor
      yomaq.gatus.endpoints = {
        ${NAME} = {
          path = "pods.${NAME}.enable";
          config = {
            group = "webapps";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [
              {
                type = "ntfy";
                failureThreshold = 3;
                description = "healthcheck failed";
              }
            ];
          };
        };
      };
    })
  ];
}
