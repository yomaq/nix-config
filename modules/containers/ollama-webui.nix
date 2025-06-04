{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "open-webui";
  IMAGE = "ghcr.io/open-webui/open-webui";

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
        "OLLAMA_BASE_URL" = "https://wsl-ollama.${config.yomaq.tailscale.tailnetName}.ts.net";
        "WEBUI_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";

        "ENABLE_PERSISTENT_CONFIG" = "false";

        "ENABLE_OPENAI_API" = "false";

        "OAUTH_CLIENT_ID" = "unused";
        "OAUTH_CLIENT_SECRET" = "unused";
        "OPENID_PROVIDER_URL" = "https://azure-tsidp.sable-chimaera.ts.net/.well-known/openid-configuration";
        "DEFAULT_USER_ROLE" = "user";

        "ENABLE_DIRECT_CONNECTIONS" = "false";

        "ENABLE_WEB_SEARCH" = "true";
        "WEB_SEARCH_ENGINE" = "searxng";
        "SEARXNG_QUERY_URL" = "https://azure-searxng.sable-chimaera.ts.net/search?q=<query>";

        "ENABLE_OAUTH_SIGNUP" = "true";
        "ENABLE_LOGIN_FORM" = "false";
      };
      description = ''
        env options
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

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/open-webui 0755 root root" ];

    virtualisation.oci-containers.containers = {
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = cfg.env;
        volumes = [ "${cfg.volumeLocation}/open-webui:/app/backend/data" ];
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
      tags = [
        "tag:ollama-server"
        "tag:ollama-access"
      ];
    };

    yomaq.homepage.groups.services.services = [
      {
        "${NAME}" = {
          icon = "si-ollama";
          href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
          siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
        };
      }
    ];

    yomaq.gatus.endpoints = [
      {
        name = "${hostName}-${NAME}";
        group = "webapps";
        url = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
        interval = "5m";
        conditions = [ "[STATUS] == 200" ];
        alerts = [
          {
            type = "ntfy";
            failureThreshold = 3;
            description = "healthcheck failed";
          }
        ];
      }
    ];
    yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
  };
}
