{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "tailscale";
  IMAGE = "ghcr.io/tailscale/tailscale";

  cfg = config.yomaq.pods.tailscaled;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;

  containerOpts = { name, config, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          enable custom ${NAME} container module
        '';
      };
      volumeLocation = mkOption {
        type = types.str;
        default = "${dontBackup}/containers/TS${name}";
        description = ''
          path to store container volumes
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "latest";
        description = ''
          container image version
        '';
      };
      TSargs = mkOption {
        type = types.str;
        default = "";
        description = ''
          TS_Extra_ARGS env var
        '';
      };
      TShostname = mkOption {
        type = types.str;
        default = "${hostName}-${name}";
        description = ''
          TS_HOSTNAME env var
        '';
      };
      TSserve = mkOption {
        type = types.str;
        default = "";
        description = ''
          port to serve on the tailnet
        '';
        example = "http://127.0.0.1:9000";
      };
      TS_CERT_DOMAIN = mkOption {
        type = types.str;
        default = "${hostName}-${name}.${tailnetName}.ts.net";
        description = ''
          domain to serve on the tailnet
        '';
      };
    };
  };
  # Helper function to create a container configuration from a submodule
  mkContainer = name: cfg: {
    image = "${IMAGE}:${cfg.imageVersion}";
    autoStart = true;
    hostname = cfg.TShostname;
    environment = {
      "TS_HOSTNAME" = cfg.TShostname;
      "TS_STATE_DIR"= "/var/lib/tailscale";
      "TS_EXTRA_ARGS" = cfg.TSargs;
      "TS_ACCEPT_DNS" = "true";
      } // lib.mkIf (cfg.TSserve != "") {
        "TS_SERVE_CONFIG" = "config/tailscaleCfg.json";
      };
    environmentFiles = [
      # need to set "TS_AUTHKEY=key" in agenix and import here
      config.age.secrets."tailscaleEnvFile".path
    ];
    volumes = [
      "${cfg.volumeLocation}/data-lib:/var/lib"
      "${cfg.volumeLocation}/dev-net-tun:/dev/net/tun"
      "${cfg.volumeLocation}/config:/config"
    ];
    extraOptions = [
      "--pull=always"
      # "--network=host"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
    ];
  };
  mkTmpfilesRules = name: cfg: [
    "d ${cfg.volumeLocation}/data-lib 0755 root root"
    "d ${cfg.volumeLocation}/dev-net-tun 0755 root root"
    "L+ ${cfg.volumeLocation}/config/tailscaleCfg.json - - - - ${(pkgs.writeText "${name}TScfg" ''
      {
      "TCP": {
        "443": {
          "HTTPS": true
        }
      },
      "Web": {
        "${cfg.TS_CERT_DOMAIN}:443": {
          "Handlers": {
            "/": {
              "Proxy": "${cfg.TSserve}"
            }
          }
        }
      },
      "AllowFunnel": {
        "${cfg.TS_CERT_DOMAIN}:443": false
      }
    }'')}"
  ];
in
{
  options.yomaq.pods = {
    tailscaled = mkOption {
      default = {};
      type = with types; attrsOf (submodule containerOpts);
      example = {};
      description = lib.mdDoc ''
        Additional tailscale containers to pair with container services to expose on the tailnet.
      '';
    };
    tailscaleAgenixKey = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/tailscaleEnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
  };




  config = mkIf (cfg != {}) {
    age.secrets."tailscaleEnvFile".file = config.yomaq.pods.tailscaleAgenixKey;

    systemd.tmpfiles.rules = lib.flatten ( lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) config.yomaq.pods.tailscaled);
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.yomaq.pods.tailscaled;
  };
}