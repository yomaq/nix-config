{
  config,
  lib,
  inputs,
  ...
}:
let
  NAME = "openwebui";
  cfg =
    if config ? inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME} then
      config.inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME}
    else
      null;

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.nixos-containers."${NAME}".enable = lib.mkEnableOption (lib.mdDoc "${NAME} Server");
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg != null && cfg.enable) {

      systemd.tmpfiles.rules = [
        "d ${backup}/nixos-containers/${NAME}/data 0755 admin"
        "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
      ];

      yomaq.homepage.groups.services.services = [
        {
          "${NAME}" = {
            icon = "si-audiobookshelf";
            href = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
            siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
          };
        }
      ];
      yomaq.monitorServices.services."container@${hostName}-${NAME}".priority = "medium";

      #will still need to set the network device name manually
      yomaq.network.useBr0 = true;

      containers."${hostName}-${NAME}" = {
        autoStart = true;
        privateNetwork = true;
        hostBridge = "br0"; # Specify the bridge name
        specialArgs = {
          inherit inputs;
        };
        bindMounts = {
          "/etc/ssh/${hostName}" = {
            hostPath = "/etc/ssh/${hostName}";
            isReadOnly = true;
          };
          "/var/lib/tailscale/" = {
            hostPath = "${dontBackup}/nixos-containers/${NAME}/tailscale";
            isReadOnly = false;
          };
          "/var/lib/open-webui" = {
            hostPath = "${backup}/nixos-containers/${NAME}/data";
            isReadOnly = false;
          };
        };
        enableTun = true;
        ephemeral = true;
        config = {
          imports = [
            inputs.self.nixosModules.yomaq
          ];
          system.stateVersion = stateVersion;
          age.identityPaths = [ "/etc/ssh/${hostName}" ];

          yomaq = {
            users.enableUsers = [ "admin" ];
            suites = {
              container.enable = true;
            };
            tailscale = {
              enable = true;
              extraUpFlags = [
                "--ssh=true"
                "--reset=true"
              ];
            };
          };

          environment.persistence."${dontBackup}".users.admin = lib.mkForce { };

          systemd.tmpfiles.rules = [ "d /var/lib/gatus/data 0755 gatus" ];

          services.open-webui = {
            enable = true;
            environment = {
              ANONYMIZED_TELEMETRY = "False";
              DO_NOT_TRACK = "True";
              SCARF_NO_ANALYTICS = "True";

              OLLAMA_BASE_URL = "https://wsl-ollama.${config.yomaq.tailscale.tailnetName}.ts.net";

              ENABLE_OPENAI_API = "false";

              OAUTH_CLIENT_ID = "unused";
              OAUTH_CLIENT_SECRET = "unused";
              OPENID_PROVIDER_URL = "https://azure-tsidp.sable-chimaera.ts.net/.well-known/openid-configuration";
              DEFAULT_USER_ROLE = "user";

              ENABLE_DIRECT_CONNECTIONS = "false";

              ENABLE_WEB_SEARCH = "true";
              WEB_SEARCH_ENGINE = "searxng";
              SEARXNG_QUERY_URL = "https://azure-searxng.sable-chimaera.ts.net/search?q=<query>";

              ENABLE_OAUTH_SIGNUP = "true";
              ENABLE_LOGIN_FORM = "false";
            };
          };

          services.caddy = {
            enable = true;
            virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
              reverse_proxy 127.0.0.1:8080
            '';
          };
        };
      };
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
            builtins.filter (host: config.inventory.hosts.${host}.nixos-containers."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          );
    })
  ];
}
