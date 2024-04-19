{ config, lib, pkgs, inputs, modulesPath, ... }:
let

  NAME = "nextcloud";

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
      "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
      "d ${dontBackup}/nixos-containers/${NAME}/nextcloud"
      "d ${dontBackup}/nixos-containers/${NAME}/db"
    ];

    yomaq.homepage.groups.services.services = [{
      "Nextcloud" = {
        icon = "si-nextcloud";
        href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
        siteMonitor = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      };
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
        "/var/lib/tailscale" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/tailscale";
          isReadOnly = false; 
        };
        "/var/lib/mysql" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/db";
          isReadOnly = false; 
        };
        "/var/lib/nextcloud" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/nextcloud";
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
          tailscale.extraUpFlags = ["--ssh=true" "--reset=true"];
          suites.container.enable = true;
        };

        # lock mariadb to a specific version 
        services.mysql.package = pkgs.mariadb.overrideAttrs (oldAttrs: {
          version = "10.11.6";
          src = oldAttrs.src.overrideAttrs {
            version = "10.11.6";
            sha256 = "sha256-HAFjRj6Y1x9HgHQWEaQJge7ivETTkmAcpJu/lI0E3Wc=";
          };
        });

        # services.postgresql.package = pkgs.postgresql_16;

        # password is only set on creation, cannot reset the password with this (also means you need to reset the password asap)
        environment.etc."nextcloud-admin-pass".text = "asdhasd&!@@SDa";
        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud28;
          hostName = "${hostName}-${NAME}.${tailnetName}.ts.net";
          config.adminpassFile = "/etc/nextcloud-admin-pass";
          configureRedis = true;
          # webserver comes from the custom nextcloud module in /modules/hosts/nextcloud/nixos.nix
          webserver = "caddy";
          collaboraHostname = "${hostName}-collaboracode.${tailnetName}.ts.net";
          https = true;
          maxUploadSize = "16G";
          notify_push.enable = true;
          autoUpdateApps.enable = true;
          database.createLocally = true;
          extraOptions = {
            "maintenance_window_start" = 8;
            default_phone_region = "US";
          };
          logType = "file";
          extraApps = {};
          appstoreEnable = true;
          ### will change soon (24.11?)
          config = {
            trustedProxies = ["127.0.0.1"];
            dbtype = "mysql";
            overwriteProtocol = "https";
            adminuser = "yomaq";
          };
        };
      };
    };

    # Default port is 9980
    virtualisation.oci-containers.containers.collaboraCode = {
      image = "docker.io/collabora/code";
      autoStart = true;
        environment = {
          # "cert_domain" = "${hostName}-collaboracode.${tailnetName}.ts.net";
          "server_name" = "${hostName}-${NAME}.${tailnetName}.ts.net";
          # "extra_params" = "--o:ssl.enable=false";
          # "aliasgroup1" = "https://${hostName}-${NAME}.${tailnetName}.ts.net:443";
        };
      extraOptions = [
          "--pull=always"
          "--network=container:TScollaboraCode"
      ];
    };
    yomaq.pods.tailscaled."TScollaboraCode".enable = true;
  };
}