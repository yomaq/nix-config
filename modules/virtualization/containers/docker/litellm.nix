{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  ### Set container name and image
  NAME = "litellm";
  IMAGE = "docker.litellm.ai/berriai/litellm-database";
  dbIMAGE = "docker.io/postgres";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.tailscale) tailnetName;

  configFile = pkgs.writeText "litellm-config.yaml" ''
    general_settings:
      forward_client_headers_to_llm_api: true
  '';
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
            agenixSecret = lib.mkOption {
              type = lib.types.path;
              default = (inputs.self + /secrets/${NAME}EnvFile.age);
              description = ''
                path to agenix secret file
              '';
            };
            ### database container
            database = {
              agenixSecret = lib.mkOption {
                type = lib.types.path;
                default = (inputs.self + /secrets/${NAME}DBEnvFile.age);
                description = ''
                  path to agenix secret file
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
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      ### agenix secrets for container
      age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
      age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;

      systemd.tmpfiles.rules = [
        # database container
        "d ${cfg.database.volumeLocation}/db 0755 root root"
      ];
      virtualisation.oci-containers.containers = {
        ### DB container
        "DB${NAME}" = {
          image = "${dbIMAGE}:16-alpine@sha256:e013e867e712fec275706a6c51c966f0bb0c93cfa8f51000f85a15f9865a28cb";
          autoStart = true;
          environmentFiles = [
            config.age.secrets."${NAME}DBEnvFile".path
            #  POSTGRES_USER=litellm
            #  POSTGRES_PASSWORD=insert_a_secure_database_password_here
            #  POSTGRES_DB=litellm
          ];
          volumes = [ "${cfg.database.volumeLocation}/db:/var/lib/postgresql/data" ];
          dependsOn = [ "TS${NAME}" ];
          extraOptions = [
            "--network=container:TS${NAME}"
          ];
        };
        ### main container
        "${NAME}" = {
          image = "${IMAGE}:latest@sha256:fc15e199e743c64beb00ac2cd6ac01e48ba17765ac792188060fa3ede7421ed7";
          autoStart = true;
          environment = {
            "PROXY_BASE_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
            "GENERIC_AUTHORIZATION_ENDPOINT" = "${config.yomaq.tailscale.tsidpUrl}/authorize";
            "GENERIC_TOKEN_ENDPOINT" = "${config.yomaq.tailscale.tsidpUrl}/token";
            "GENERIC_USERINFO_ENDPOINT" = "${config.yomaq.tailscale.tsidpUrl}/userinfo";
            "GENERIC_USER_ID_ATTRIBUTE" = "email";
            "AUTO_REDIRECT_UI_LOGIN_TO_SSO" = "true";
            "STORE_MODEL_IN_DB" = "True";
            "CONFIG_FILE_PATH" = "/app/config.yaml";
          };
          environmentFiles = [
            config.age.secrets."${NAME}EnvFile".path
            #  DATABASE_URL=postgresql://litellm:insert_a_secure_database_password_here@127.0.0.1:5432/litellm
            #  LITELLM_MASTER_KEY=sk-insert_a_master_key_here
            #  GENERIC_CLIENT_ID=insert_the_tsidp_oauth_client_id_here
            #  GENERIC_CLIENT_SECRET=insert_the_tsidp_oauth_client_secret_here
          ];
          volumes = [ "${configFile}:/app/config.yaml:ro" ];
          dependsOn = [
            "TS${NAME}"
            "DB${NAME}"
          ];
          extraOptions = [
            "--network=container:TS${NAME}"
          ];
        };
      };
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:4000";
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
            url = "https://${host}-${NAME}.${config.yomaq.tailscale.tailnetName}.ts.net/health/liveliness";
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
              icon = "mdi-api";
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
