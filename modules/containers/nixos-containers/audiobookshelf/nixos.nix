{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
let
  NAME = "audiobookshelf";
  cfg = config.yomaq.nixos-containers."${NAME}";

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;
in
{
  options.yomaq.nixos-containers."${NAME}".enable = lib.mkEnableOption (lib.mdDoc "${NAME} Server");

  config = lib.mkIf cfg.enable {

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
        "/var/lib/audiobookshelf" = {
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

        services.audiobookshelf = {
          enable = true;
        };

        services.caddy = {
          enable = true;
          virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
            reverse_proxy 127.0.0.1:8000
          '';
        };
      };
    };
  };
}
