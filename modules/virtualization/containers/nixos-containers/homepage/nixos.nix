{
  config,
  lib,
  inputs,
  ...
}:
let
  NAME = "homepage";
  cfg = config.inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;

in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.nixos-containers."${NAME}" = {
            enable = lib.mkEnableOption (lib.mdDoc "${NAME} Server");
            storage = lib.mkOption {
              description = "persistent file location";
              type = lib.types.str;
              default = dontBackup;
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      yomaq.homepage.enable = true;

      yomaq.monitorServices.services."container@${hostName}-${NAME}".priority = "medium";

      systemd.tmpfiles.rules = [ "d ${cfg.storage}/nixos-containers/${NAME}/tailscale" ];

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
          "/var/lib/tailscale" = {
            hostPath = "${cfg.storage}/nixos-containers/${NAME}/tailscale";
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

          inventory.hosts."${hostName}-${NAME}" = {
            users.enableUsers = [ "admin" ];
            glances.homepageMonitor = false;
          };
          yomaq = {
            tailscale.extraUpFlags = [
              "--ssh=true"
              "--reset=true"
            ];
            suites.container.enable = true;
            # homepage-dashboard.enable = true;
            homepage.enable = true;
          };
          services.homepage-dashboard.enable = true;
          systemd.services.homepage-dashboard.serviceConfig.Environment = [
            "HOMEPAGE_ALLOWED_HOSTS=${hostName}-${NAME}.${tailnetName}.ts.net"
          ];

          yomaq.homepage = {
            widgets = {
              search = {
                provider = "custom";
                url = "https://azure-searxng.sable-chimaera.ts.net/?q=";
                focus = true;
                target = "_blank";
              };
              openmeteo = {
                label = "Okc";
                latitude = "35.46756";
                longitude = "-97.51643";
                timezone = "America/Chicago";
                units = "Imperial";
                cache = 5;
                format = {
                  maximumFractionDigits = 1;
                };
              };
            };
            settings = {
              title = "{{HOMEPAGE_VAR_NAME}}";
              background = {
                blur = "sm";
                saturate = 50;
                brightness = 50;
                opacity = 50;
              };
              color = "slate";
              theme = "dark";
              hideVersion = "true";
              useEqualHeights = true;
              favicon = "https://azure-dufs.sable-chimaera.ts.net/strawberry/favicon.ico";
              statusStyle = "dot";
            };
          };

          systemd.tmpfiles.rules = [ 
            "d /etc/homepage-dashboard/logs"
            "f /etc/homepage-dashboard/proxmox.yaml"
          ];

          services.caddy = {
            enable = true;
            virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
              reverse_proxy 127.0.0.1:8082
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
