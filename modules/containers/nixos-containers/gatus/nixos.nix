{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  NAME = "gatus";
  cfg = config.inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME};

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

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      # "d ${backup}/nixos-containers/${NAME}/data"
      "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
    ];

    yomaq.homepage.groups.services.services = [
      {
        "${NAME}" = {
          icon = "mdi-list-status";
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
        inherit inputs lib;
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
        # "/var/lib/gatus-data" = {
        #   hostPath = "${backup}/nixos-containers/${NAME}/data";
        #   isReadOnly = false;
        # };
      };
      enableTun = true;
      ephemeral = true;
      config = {
        imports = [
          inputs.self.nixosModules.yomaq
          inputs.self.nixosModules.pods
        ];
        system.stateVersion = stateVersion;
        age.identityPaths = [ "/etc/ssh/${hostName}" ];

        inventory.hosts."${hostName}-${NAME}".users.enableUsers = [ "admin" ];
        yomaq = {
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

        yomaq.gatus.enable = true;

        systemd.services.gatus.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";

        services.gatus = {
          enable = true;
          settings = {
            web.port = 8080;
            # storage = {
            #   type = "sqlite";
            #   path = "/var/lib/gatus-data/data.db";
            # };
            # external-endpoints = [{
            #   name = "ext-ep-test";
            #   group = "test";
            #   token = "potato";
            # }];
            # curl -X POST \
            #   https://azure-gatus.sable-chimaera.ts.net/api/v1/endpoints/test_ext-ep-test/external\?success\=true\&error\= \
            #   -H 'Authorization: Bearer potato'

            alerting = {
              ntfy = {
                url = "${config.yomaq.ntfy.ntfyUrl}";
                topic = "${config.yomaq.ntfy.defaultTopic}";
                priority = 3;
                default-alert = {
                  enable = true;
                  failure-threshold = 10;
                  success-threshold = 10;
                  send-on-resolved = true;
                };
              };
            };
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
  };
}
