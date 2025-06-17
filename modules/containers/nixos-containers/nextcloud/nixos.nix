{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  NAME = "nextcloud";
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

      systemd.tmpfiles.rules = [
        "d ${cfg.storage}/nixos-containers/${NAME}/tailscale"
        "d ${cfg.storage}/nixos-containers/${NAME}/nextcloud"
        "d ${cfg.storage}/nixos-containers/${NAME}/db"
      ];

      yomaq.homepage.groups.services.services = [
        {
          "Nextcloud" = {
            icon = "si-nextcloud";
            href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
            siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
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
          "/var/lib/tailscale" = {
            hostPath = "${cfg.storage}/nixos-containers/${NAME}/tailscale";
            isReadOnly = false;
          };
          "/var/lib/mysql" = {
            hostPath = "${cfg.storage}/nixos-containers/${NAME}/db";
            isReadOnly = false;
          };
          "/var/lib/nextcloud" = {
            hostPath = "${cfg.storage}/nixos-containers/${NAME}/nextcloud";
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
          };

          # lock mariadb to a specific version
          services.mysql.package = pkgs.mariadb_114;

          # password is only set on creation, cannot reset the password with this (also means you need to reset the password asap)
          environment.etc."nextcloud-admin-pass".text = "asdhasd&!@@SDa";
          services.nextcloud = {
            enable = true;
            package = pkgs.nextcloud31;
            hostName = "${hostName}-${NAME}.${tailnetName}.ts.net";
            config.adminpassFile = "/etc/nextcloud-admin-pass";
            configureRedis = true;
            # webserver comes from the custom nextcloud module in /modules/hosts/nextcloud/nixos.nix
            webserver = "caddy";
            collaboraHostname = "${hostName}-collaboracode.${tailnetName}.ts.net";
            https = true;
            maxUploadSize = "16G";
            notify_push.enable = true;
            extraApps = {
              inherit (pkgs.nextcloud31Packages.apps) oidc_login memories previewgenerator;
            };
            extraAppsEnable = true;
            autoUpdateApps.enable = true;
            database.createLocally = true;
            phpOptions."opcache.interned_strings_buffer" = "24";
            settings = {
              "maintenance_window_start" = 8;
              default_phone_region = "US";
              trustedProxies = [ "127.0.0.1" ];
              overwriteProtocol = "https";

              # for use with this tsipd and  https://github.com/pulsejet/nextcloud-oidc-login
              oidc_login_client_id = "unused";
              oidc_login_client_secret = "unused";
              oidc_login_provider_url = "https://${hostName}-tsidp.${tailnetName}.ts.net";
              oidc_login_attributes = {
                id = "username";
                mail = "email";
              };
            };
            appstoreEnable = true;
            config = {
              dbtype = "mysql";
              adminuser = "admin";
            };
          };
        };
      };

      # Default port is 9980
      virtualisation.oci-containers.containers.collaboraCode = {
        image = "docker.io/collabora/code";
        autoStart = true;
        environment = {
          "server_name" = "${hostName}-${NAME}.${tailnetName}.ts.net";
        };
        extraOptions = [
          "--pull=always"
          "--network=container:TScollaboraCode"
        ];
      };
      yomaq.pods.tailscaled."TScollaboraCode".enable = true;
    })
    (lib.mkIf config.yomaq.gatus.enable {
      # Add dufs to the list of services to monitor
      yomaq.gatus.endpoints = {
        ${NAME} = {
          path = "nixos-containers.${NAME}.enable";
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
