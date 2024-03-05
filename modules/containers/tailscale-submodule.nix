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
        default = "${dontBackup}/containers/${name}";
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
     enableFunnel = mkOption {
        type = lib.types.enum [ "true" "false" ];
        default = "false";
        description = ''
          if you are sure you want to enable funnel
        '';
      };
    };
  };
  # Helper function to create a container configuration from a submodule
  mkContainer = name: cfg: {
      image = "${IMAGE}:${cfg.imageVersion}";
      autoStart = true;
      hostname = cfg.TShostname;
      environment = lib.mkMerge [
      {
          "TS_HOSTNAME" = cfg.TShostname;
          "TS_STATE_DIR" = "/var/lib/tailscale";
          "TS_EXTRA_ARGS" = lib.strings.concatStrings [ "--advertise-tags=tag:container" ] + cfg.TSargs;
          "TS_ACCEPT_DNS" = "true";
      }
      (lib.mkIf (cfg.TSserve != "") {
          "TS_SERVE_CONFIG" = "config/tailscaleCfg.json";
      })
      ];
      environmentFiles = [
        # need to set "TS_AUTHKEY=key" in agenix and import here
        config.age.secrets."tailscaleOAuthEnvFile".path
      ];
      volumes = [
        "${cfg.volumeLocation}/data-lib:/var/lib"
        "/dev/net/tun:/dev/net/tun"
        "${(pkgs.writeText "${name}TScfg" 
          ''{
            "TCP": {
              "443": {
                "HTTPS": true
              }
            },
            "Web": {
              "${cfg.TShostname}.${tailnetName}.ts.net:443": {
                "Handlers": {
                  "/": {
                    "Proxy": "${cfg.TSserve}"
                  }
                }
              }
            },
            "AllowFunnel": {
              "${cfg.TShostname}.${tailnetName}.ts.net:443": ${cfg.enableFunnel}
            }
          }'')}:/config/tailscaleCfg.json"
      ];
      extraOptions = [
        "--pull=always"
        "--cap-add=net_admin"
        "--cap-add=sys_module"
      ];
  };
  mkTmpfilesRules = name: cfg: [
    "d ${cfg.volumeLocation}/data-lib 0755 root root"
    "d ${cfg.volumeLocation}/dev-net-tun 0755 root root"
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
      default = (inputs.self + /secrets/tailscaleOAuthEnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
  };
  config = mkIf (cfg != {}) {
    age.secrets."tailscaleOAuthEnvFile".file = config.yomaq.pods.tailscaleAgenixKey;

    systemd.tmpfiles.rules = lib.flatten ( lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) config.yomaq.pods.tailscaled);
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.yomaq.pods.tailscaled;
  };
}