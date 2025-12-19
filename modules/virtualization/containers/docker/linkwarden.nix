{
  config,
  lib,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "linkwarden";
  IMAGE = "ghcr.io/linkwarden/linkwarden";
  dbIMAGE = "docker.io/postgres";

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
            agenixSecret = lib.mkOption {
              type = lib.types.path;
              default = (inputs.self + /secrets/${NAME}EnvFile.age);
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
            imageVersion = lib.mkOption {
              type = lib.types.str;
              default = "latest";
              description = ''
                container image version
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
              imageVersion = lib.mkOption {
                type = lib.types.str;
                default = "16-alpine";
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
      ### agenix secrets for container
      age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
      age.secrets."${NAME}DBEnvFile".file = cfg.database.agenixSecret;

      systemd.tmpfiles.rules = [
        # main container
        "d ${cfg.volumeLocation}/data 0755 4000 4000"
        # database container
        "d ${cfg.database.volumeLocation}/db 0755 root root"
      ];
      virtualisation.oci-containers.containers = {
        ### DB container
        "DB${NAME}" = {
          image = "${dbIMAGE}:${cfg.database.imageVersion}";
          autoStart = true;
          # environment = {
          #     "POSTGRES_PASSWORD" = "password";
          # };
          environmentFiles = [
            config.age.secrets."${NAME}DBEnvFile".path
            #  POSTGRES_PASSWORD=password #insert your secure database password!
          ];
          volumes = [ "${cfg.database.volumeLocation}/db:/var/lib/postgresql/data" ];
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
            "NEXT_PUBLIC_AUTH0_ENABLED" = "true";
            # OIDC works, but there is no way to configure the username claim, so it currently generates a nonesense username
            "AUTH0_ISSUER" = "https://azure-tsidp.sable-chimaera.ts.net";
            "AUTH0_CLIENT_ID" = "unused";
            "AUTH0_CLIENT_SECRET" = "unused";
            "NEXTAUTH_URL" = "https://${hostName}-${NAME}.${tailnetName}.ts.net/api/v1/auth";
          };
          environmentFiles = [
            config.age.secrets."${NAME}EnvFile".path
            #  DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@127.0.0.1:5432/postgres
            #  NEXTAUTH_SECRET=very_sensitive_secret
            #  NEXTAUTH_URL=http://localhost:3000/api/v1/auth
          ];
          volumes = [ "${cfg.volumeLocation}/data:/data/data" ];
          extraOptions = [
            "--pull=always"
            "--network=container:TS${NAME}"
          ];
        };
      };
      yomaq.pods.tailscaled."TS${NAME}" = {
        TSserve = {
          "/" = "http://127.0.0.1:3000";
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
              icon = "mdi-bookmark-box";
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
