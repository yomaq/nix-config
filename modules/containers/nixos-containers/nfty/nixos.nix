{
  config,
  lib,
  inputs,
  ...
}:
let
  NAME = "ntfy";
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
        "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
        "d ${backup}/nixos-containers/${NAME}/data 0755 admin"
      ];

      yomaq.homepage.groups.services.services = [
        {
          "${NAME}" = {
            icon = "mdi-bell-badge";
            href = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
            siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
          };
        }
      ];

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

          services.ntfy-sh = {
            enable = true;
            settings = {
              base-url = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
              listen-http = ":8080";
              upstream-base-url = "https://ntfy.sh";
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
