{
  config,
  lib,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "open-webui";
  IMAGE = "ghcr.io/open-webui/open-webui";

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
                "OLLAMA_BASE_URL" = "https://wsl-ollama.${config.yomaq.tailscale.tailnetName}.ts.net";
                "WEBUI_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";

                "ENABLE_PERSISTENT_CONFIG" = "false";

                "ENABLE_OPENAI_API" = "false";

                "OPENID_PROVIDER_URL" = "${config.yomaq.tailscale.tsidpUrl}/.well-known/openid-configuration";
                "DEFAULT_USER_ROLE" = "user";

                "ENABLE_DIRECT_CONNECTIONS" = "false";

                "ENABLE_WEB_SEARCH" = "true";
                "WEB_SEARCH_ENGINE" = "searxng";
                "SEARXNG_QUERY_URL" = "https://azure-searxng.sable-chimaera.ts.net/search?q=<query>";

                "ENABLE_OAUTH_SIGNUP" = "true";
                "ENABLE_LOGIN_FORM" = "false";
                "OAUTH_MERGE_ACCOUNTS_BY_EMAIL" = "true";
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

      systemd.tmpfiles.rules = [ "d ${cfg.volumeLocation}/open-webui 0755 root root" ];

      age.secrets."${NAME}OAuthEnvFile".file = (inputs.self + /secrets/${NAME}OAuthEnvFile.age);

      virtualisation.oci-containers.containers = {
        "${NAME}" = {
          image = "ghcr.io/open-webui/open-webui:latest@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e";
          autoStart = true;
          environment = cfg.env;
          environmentFiles = [
            config.age.secrets."${NAME}OAuthEnvFile".path
            #  OAUTH_CLIENT_ID=insert_the_tsidp_oauth_client_id_here
            #  OAUTH_CLIENT_SECRET=insert_the_tsidp_oauth_client_secret_here
          ];
          volumes = [ "${cfg.volumeLocation}/open-webui:/app/backend/data" ];
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
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
                "failure-threshold" = 3;
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
              icon = "si-ollama";
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
