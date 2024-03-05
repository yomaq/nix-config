{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "tailscale";
  IMAGE = "ghcr.io/tailscale/tailscale";

  cfg = config.yomaq.pods.tailscaled;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;

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
    };
  };
  # Helper function to create a container configuration from a submodule
  mkContainer = name: cfg: {
    image = "${IMAGE}:${cfg.imageVersion}";
    autoStart = true;
    environment = {
    "TS_HOSTNAME" =cfg.TShostname;
    "TS_STATE_DIR"= "/var/lib/tailscale";
    "TS_EXTRA_ARGS" = cfg.TSargs;
    "TS_ACCEPT_DNS" = "true";
    };
    environmentFiles = [
      # need to set "TS_AUTHKEY=key" in agenix and import here
      config.age.secrets."tailscaleEnvFile".path
    ];
    volumes = [
      "${cfg.volumeLocation}/data-lib:/var/lib"
      "${cfg.volumeLocation}/dev-net-tun:/dev/net/tun"
    ];
    extraOptions = [
      "--pull=always"
      "--network=host"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
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
      default = (inputs.self + /secrets/tailscaleEnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
  };




  config = mkIf cfg != {} {
    age.secrets."tailscaleEnvFile".file = config.yomaq.pods.tailscaleAgenixKey;

    systemd.tmpfiles.rules = lib.concatMapAttrs mkTmpfilesRules config.example.pods.tailscaled;
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.example.pods.tailscaled;
  };
}