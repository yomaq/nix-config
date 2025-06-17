{
  config,
  lib,
  inputs,
  ...
}:
let
  NAME = "homepage";
  cfg =
    if config ? inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME} then
      config.inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME}
    else
      null;

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
    (lib.mkIf (cfg != null && cfg.enable) {

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

          yomaq = {
            users.enableUsers = [ "admin" ];
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

          systemd.tmpfiles.rules = [ "d /etc/homepage-dashboard/logs" ];
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
      # Add dufs to the list of services to monitor
      yomaq.gatus.endpoints = {
        homepage = {
          path = "nixos-containers.homepage.enable";
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
