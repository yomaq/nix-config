{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ### Set container name and image
  NAME = "tailscale";
  IMAGE = "ghcr.io/tailscale/tailscale";

  cfg = config.yomaq.pods.tailscaled;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;

  containerOpts =
    { name, ... }:
    let
      # this allows container modules to name their TS submodule "TS${containerName}" so it won't overlap with the main container
      # but the tailscale node won't have the "TS" prefix, which is unnecessary
      startsWithTS = lib.substring 0 2 name == "TS";
      noTSname = if startsWithTS then lib.substring 2 (-1) name else name;
    in
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            enable custom ${NAME} container module
          '';
        };
        volumeLocation = lib.mkOption {
          type = lib.types.str;
          default = "${dontBackup}/containers/tailscale/${name}";
          description = ''
            path to store container volumes
          '';
        };
        TSargs = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            TS_Extra_ARGS env var
          '';
        };
        TShostname = lib.mkOption {
          type = lib.types.str;
          default = "${hostName}-${noTSname}";
          description = ''
            TS_HOSTNAME env var
          '';
        };
        TSserve = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          description = ''
            paths that should map to ports for tailscale serve
          '';
          example = {
            "/" = "http://127.0.0.1:9000";
          };
        };
        enableFunnel = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            if you are sure you want to enable funnel
          '';
        };
        tags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "tag:lockdown" ];
          description = ''
            list of tags owned by "tag:container" to assign to the container
          '';
        };
      };
    };
  # Helper function to create a container configuration from a submodule
  mkContainer =
    name: cfg:
    let
      formatTags = builtins.concatStringsSep "," cfg.tags;
      PathsToMap = _a: b: { Proxy = "${b}"; };
      Serveconfig = {
        TCP."443".HTTPS = true;
        Web."${cfg.TShostname}.${tailnetName}.ts.net:443".Handlers = lib.mapAttrs PathsToMap cfg.TSserve;
        AllowFunnel = {
          "${cfg.TShostname}.${tailnetName}.ts.net:443" = cfg.enableFunnel;
        };
      };
    in
    {
      image = "ghcr.io/tailscale/tailscale:latest";
      autoStart = true;
      hostname = cfg.TShostname;
      environment = lib.mkMerge [
        {
          "TS_HOSTNAME" = cfg.TShostname;
          "TS_STATE_DIR" = "/var/lib/tailscale";
          # "TS_USERSPACE" = "false";
          "TS_EXTRA_ARGS" = "--advertise-tags=" + formatTags + " --accept-dns=true " + cfg.TSargs;
        }
        (lib.mkIf (cfg.TSserve != { }) {
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
        "${
          (pkgs.writeTextFile {
            name = "${name}TScfg";
            text = builtins.toJSON Serveconfig;
          })
        }:/config/tailscaleCfg.json"
      ];
      extraOptions = [
        "--pull=always"
        "--cap-add=net_admin"
        "--cap-add=sys_module"
      ];
    };
  mkTmpfilesRules = _name: cfg: [ "d ${cfg.volumeLocation}/data-lib 0755 root root" ];
in
{
  options.yomaq.pods = {
    tailscaled = lib.mkOption {
      default = { };
      type = with lib.types; attrsOf (submodule containerOpts);
      example = { };
      description = lib.mdDoc ''
        Additional tailscale containers to pair with container services to expose on the tailnet.
      '';
    };
    tailscaleAgenixKey = lib.mkOption {
      type = lib.types.path;
      default = (inputs.self + /secrets/tailscaleOAuthEnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
  };
  config = lib.mkIf (cfg != { }) {
    age.secrets."tailscaleOAuthEnvFile".file = config.yomaq.pods.tailscaleAgenixKey;

    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) config.yomaq.pods.tailscaled
    );
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.yomaq.pods.tailscaled;

    yomaq.monitorServices.services = lib.mkMerge (
      lib.mapAttrsToList (name: _: {
        "docker-${name}" = {
          priority = "medium";
        };
      }) cfg
    );

  };
}

# This allows easy creation of tailscale containers to pair along side other dockerized services.
# Configuration looks like:

#   # yomaq.pods.tailscaled."TS${containerName}" = {
#   #   TSserve = {
#   #     "/" = "http://127.0.0.1:3000";
#   #   };
#   #   tags = [ "tag:tagName" ];
#   # };

# Then just make sure the docker containers are all set to use the tailscale container for their networking.
# This will setup the Tailscale Serve config, as well as tagging the device.
