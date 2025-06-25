{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  NAME = "tsidp";
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      systemd.tmpfiles.rules = [
        "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
        "d ${backup}/nixos-containers/${NAME}/tsidp"
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
          "/var/lib/tailscale/tsidp" = {
            hostPath = "${backup}/nixos-containers/${NAME}/tsidp";
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

          systemd.services.tsidp = {
            description = "Tailscale OIDC Identity Provider";
            wantedBy = [ "multi-user.target" ];
            requires = [ "tailscaled.service" ];

            serviceConfig = {
              ExecStartPre = pkgs.writeShellScript "wait-for-tailscale" ''
                while ! ${pkgs.unstable.tailscale}/bin/tailscale status &>/dev/null; do
                  echo "Waiting for tailscale to be ready..."
                  sleep 1
                done
              '';
              ExecStart = "${pkgs.unstable.tailscale}/bin/tsidp --use-local-tailscaled=true --dir=/var/lib/tailscale/tsidp --port=443";
              Environment = [ "TAILSCALE_USE_WIP_CODE=1" ];
              Restart = "always";
            };
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
