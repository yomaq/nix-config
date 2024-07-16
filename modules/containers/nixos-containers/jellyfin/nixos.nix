{ config, lib, pkgs, inputs, modulesPath, ... }:
let

  NAME = "jellyfin";

  cfg = config.yomaq.nixos-containers."${NAME}";

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;
in
{
  options.yomaq.nixos-containers."${NAME}".enable = lib.mkEnableOption (lib.mdDoc "${NAME}");

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
      "d ${dontBackup}/nixos-containers/${NAME}/data 0755 admin"
    ];

    yomaq.homepage.groups.services.services = [{
      "${NAME}" = {
        icon = "si-jellyfin";
        href = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
        siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
      };
    }];

    yomaq.gatus.endpoints = [{
      name = "${hostName}-${NAME}";
      group = "webapps";
      url = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
      interval = "5m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          failureThreshold = 3;
          description = "healthcheck failed";
        }
      ];
    }];

    #will still need to set the network device name manually
    yomaq.network.useBr0 = true;

    containers."${hostName}-${NAME}" = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br0"; # Specify the bridge name
      specialArgs = { inherit inputs; };
      bindMounts = { 
        "/etc/ssh/${hostName}" = { 
          hostPath = "/etc/ssh/${hostName}";
          isReadOnly = true; 
        };
        "/var/lib/tailscale/" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/tailscale";
          isReadOnly = false; 
        };
        "${dontBackup}/nixos-containers/${NAME}/userdata" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/userdata";
          isReadOnly = false; 
        };
      };
      enableTun = true;
      ephemeral = true;
      config = {
        imports = [
          inputs.self.nixosModules.yomaq
          (inputs.self + /users/admin)
          ];
        system.stateVersion = stateVersion;
        age.identityPaths = ["/etc/ssh/${hostName}"];

        yomaq = {
          suites = {
            container.enable = true;
            };
          tailscale = {
            enable = true;
            extraUpFlags = ["--ssh=true" "--reset=true"];
          };
        };

        environment.persistence."${dontBackup}".users.admin = lib.mkForce {};

        services.jellyfin = {
          enable = true;
          dataDir = "${dontBackup}/nixos-containers/${NAME}/userdata";
        };

        # 8096/tcp is used by default for HTTP traffic. You can change this in the dashboard.
        # 8920/tcp is used by default for HTTPS traffic. You can change this in the dashboard.
        # 1900/udp is used for service auto-discovery. This is not configurable.
        # 7359/udp is also used for auto-discovery. This is not configurable.

        services.caddy = {
          enable = true;
          virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
            reverse_proxy 127.0.0.1:8920
          '';
        };
      };
    };
  };
}