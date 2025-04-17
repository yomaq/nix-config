{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
let
  NAME = "openvscode";
  cfg = config.yomaq.nixos-containers.openvscode;

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;
in
{
  options.yomaq.nixos-containers.openvscode.enable = lib.mkEnableOption (
    lib.mdDoc "Openvscode Server"
  );

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
      "d ${dontBackup}/nixos-containers/${NAME}/data 0755 admin"
      "d ${dontBackup}/nixos-containers/${NAME}/userdata 0755 admin"
      "d ${dontBackup}/nixos-containers/${NAME}/extensions 0755 admin"
      "d ${dontBackup}/nixos-containers/${NAME}/admin 0755 admin"
    ];

    yomaq.homepage.groups.services.services = [
      {
        "Code Server" = {
          icon = "si-visualstudiocode";
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
        "${dontBackup}/nixos-containers/${NAME}/data" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/data";
          isReadOnly = false;
        };
        "${dontBackup}/nixos-containers/${NAME}/userdata" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/userdata";
          isReadOnly = false;
        };
        "${dontBackup}/nixos-containers/${NAME}/extensions" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/extensions";
          isReadOnly = false;
        };
        "/home/admin" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/admin";
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

        services.openvscode-server = {
          enable = true;
          user = "admin";
          host = "127.0.0.1";
          withoutConnectionToken = true;
          telemetryLevel = "off";
          serverDataDir = "${dontBackup}/nixos-containers/${NAME}/data";
          userDataDir = "${dontBackup}/nixos-containers/${NAME}/userdata";
          extensionsDir = "${dontBackup}/nixos-containers/${NAME}/extensions";
        };

        services.caddy = {
          enable = true;
          virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
            reverse_proxy 127.0.0.1:3000
          '';
        };
      };
    };
  };
}
