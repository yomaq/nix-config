{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "nextcloud";
  baseDir = "/var/lib/microvms/${hostName}";
  hostName =  config.networking.hostName;
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    microvm = {
      hotplugMem = 3584;
      vcpu = 4;
    };
    microvm.shares = [        
      {
        source = "${config.yomaq.impermanence.backupStorage}/microvms/${vmName}";
        mountPoint = "/storage/save";
        tag = "storageSave";
        proto = "virtiofs";
        socket = "${baseDir}/storageSave.socket";
      }
    ];

    services.mysql.package = pkgs.mariadb_114;

    environment.etc."nextcloud-admin-pass".text = "asdhasd&!@@SDa";
    age.secrets.nextcloudEnvFile.file = (inputs.self + /secrets/nextcloudEnvFile.age);
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      secretFile = config.age.secrets.nextcloudEnvFile.path;
      hostName = "${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
      config.adminpassFile = "/etc/nextcloud-admin-pass";
      configureRedis = true;
      # webserver comes from the custom nextcloud module in /modules/hosts/nextcloud/nixos.nix
      webserver = "caddy";
      collaboraHostname = "127.0.0.1";
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

        "auth.webauthn.enabled" = false;
        # for use with this tsipd and  https://github.com/pulsejet/nextcloud-oidc-login
        # oidc_login_client_id = "unused";
        # oidc_login_client_secret = "unused";
        allow_user_to_change_display_name = true;
        oidc_login_disable_registration = false;
        oidc_login_hide_password_form = true;
        oidc_login_provider_url = "https://tsidp.${config.yomaq.tailscale.tailnetName}.ts.net";
        oidc_login_button_text = "Log in with Tailscale";
        oidc_login_attributes = {
          id = "email";
          mail = "email";
        };
      };
      appstoreEnable = true;
      config = {
        dbtype = "mysql";
        adminuser = "admin";
      };
    };


    services.collabora-online = {
      enable = true;
      port = 9980;
      settings = {
        server_name = "${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
      };
      aliasGroups = [
        {
          host = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net:443";
          aliases = [ ];
        }
      ];
    };

    # virtualisation.oci-containers.containers.collaboraCode = {
    #   image = "docker.io/collabora/code";
    #   autoStart = true;
    #   environment = {
    #     "server_name" = "${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
    #     "aliasgroup1" = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net:443";
    #   };
    #   extraOptions = [
    #     "--pull=always"
    #     "--network=host"
    #   ];
    # };
    # inventory.hosts."${config.networking.hostName}".docker.enable = true;

    environment.persistence."/storage/save" = lib.mkForce {
      directories = [
        "/var/lib/mysql"
        "/var/lib/nextcloud"
      ];
    };

    environment.persistence."/persist" = lib.mkForce {
      directories = [
        "/var/lib/docker"
      ];
    };

  };
}
