{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.yomaq.homepage-dashboard;
in
{
  options = {
    yomaq.homepage-dashboard = {
      enable = lib.mkEnableOption (lib.mdDoc "Homepage Dashboard");

      package = lib.mkPackageOptionMD pkgs "homepage-dashboard" { };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = lib.mdDoc "Open ports in the firewall for Homepage.";
      };

      listenPort = lib.mkOption {
        type = lib.types.int;
        default = 8082;
        description = lib.mdDoc "Port for Homepage to bind to.";
      };
      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = lib.mdDoc ''
          You can include environment variables in your config files to protect sensitive information. Note:

          Environment variables must start with HOMEPAGE_VAR_ or HOMEPAGE_FILE_
          The value of env var HOMEPAGE_VAR_XXX will replace {{HOMEPAGE_VAR_XXX}} in any config
          The value of env var HOMEPAGE_FILE_XXX must be a file path, the contents of which will be used to replace {{HOMEPAGE_FILE_XXX}} in any config
          https://gethomepage.dev/latest/installation/docker/#using-environment-secrets
        '';
      };
      settings = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.submodule {
            freeformType = (pkgs.formats.yaml { }).type;
        });
        description = lib.mdDoc ''
          YAML Value configuration for Homepage settings.
          See link for options and how to configure.
          https://gethomepage.dev/latest/configs/settings/
        '';
      };
      bookmarks = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
            freeformType = (pkgs.formats.yaml { }).type;
        }));
        description = lib.mdDoc ''
          YAML Value configuration for Homepage settings.
          See link for options and how to configure.
          https://gethomepage.dev/latest/configs/bookmarks/
        '';
      };
      docker = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.submodule {
            freeformType = (pkgs.formats.yaml { }).type;
        });
        description = lib.mdDoc ''
          YAML Value configuration for Homepage settings.
          See link for options and how to configure.
          https://gethomepage.dev/latest/configs/docker/
        '';
      };
      kubernetes = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
            freeformType = (pkgs.formats.yaml { }).type;
        }));
        description = lib.mdDoc ''
          YAML Value configuration for Homepage settings.
          See link for options and how to configure.
          https://gethomepage.dev/latest/configs/kubernetes/
        '';
      };
      widgets = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
            freeformType = (pkgs.formats.yaml { }).type;
        }));
        description = lib.mdDoc ''
          YAML Value configuration for Homepage settings.
          See link for options and how to configure.
          https://gethomepage.dev/latest/configs/service-widgets/
        '';
      };
      services = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
            freeformType = (pkgs.formats.yaml { }).type;
        }));
        description = lib.mdDoc ''
          YAML Value configuration for Homepage settings.
          See link for options and how to configure.
          https://gethomepage.dev/latest/configs/services/
        '';
      };
      css = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc "custom css for Homepage. See link for how to configure. https://gethomepage.dev/latest/configs/custom-css-js/";
      };
      js = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc "custom js for Homepage. See link for how to configure. https://gethomepage.dev/latest/configs/custom-css-js/";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.homepage-dashboard = {
      description = "Homepage Dashboard";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOMEPAGE_CONFIG_DIR = "/var/lib/homepage-dashboard";
        PORT = "${toString cfg.listenPort}";
      };

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "homepage-dashboard";
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";
      } // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };

    systemd.tmpfiles.rules = lib.flatten [
      (lib.optional (cfg.settings != null) "L+ /var/lib/homepage-dashboard/settings.yaml 755 root root - ${(pkgs.formats.yaml { }).generate "settings.yaml" cfg.settings}")
      (lib.optional (cfg.bookmarks != null) "L+ /var/lib/homepage-dashboard/bookmarks.yaml - root root - ${(pkgs.formats.yaml { }).generate "bookmarks.yaml" cfg.bookmarks}")
      (lib.optional (cfg.docker != null) "L+ /var/lib/homepage-dashboard/docker.yaml - root root - ${(pkgs.formats.yaml { }).generate "docker.yaml" cfg.docker}")
      (lib.optional (cfg.kubernetes != null) "L+ /var/lib/homepage-dashboard/kubernetes.yaml - root root - ${(pkgs.formats.yaml { }).generate "kubernetes.yaml" cfg.kubernetes}")
      (lib.optional (cfg.services != null) "L+ /var/lib/homepage-dashboard/services.yaml - root root - ${(pkgs.formats.yaml { }).generate "services.yaml" cfg.services}")
      (lib.optional (cfg.widgets != null) "L+ /var/lib/homepage-dashboard/widgets.yaml - root root - ${(pkgs.formats.yaml { }).generate "widgets.yaml" cfg.widgets}")
      (lib.optional (cfg.css != null) "L+ /var/lib/homepage-dashboard/custom.css - root root - ${(pkgs.writeText "custom.css" cfg.css)}")
      (lib.optional (cfg.js != null) "L+ /var/lib/homepage-dashboard/custom.js - root root - ${(pkgs.writeText "custom.js" cfg.js)}")
    ];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.listenPort ];
    };
  };
}