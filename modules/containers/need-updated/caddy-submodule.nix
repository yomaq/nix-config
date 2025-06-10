####

#### NOT WORKING

####
{
  config,
  lib,
  ...
}:

with lib;
let
  ### Set container name and image
  NAME = "caddy";
  IMAGE = "docker.io/caddy";

  cfg = config.yomaq.pods.tailscaled;
  inherit (config.yomaq.impermanence) dontBackup;

  containerOpts =
    { name, ... }:
    let
      startsWithCADDY = substring 0 5 name == "CADDY";
      noCADDYname = if startsWithCADDY then substring 5 (-1) name else name;
    in
    {
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
          default = "${dontBackup}/containers/caddy/${name}";
          description = ''
            path to store container volumes
          '';
        };
        TSsockLocation = mkOption {
          type = types.str;
          default = "${dontBackup}/containers/tailscale/${noCADDYname}/tmp/tailscaled.sock";
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
        caddyfile = mkOption {
          type = types.str;
          default = "";
          description = ''
            caddyfile
          '';
          example = "";
        };
      };
    };
  # Helper function to create a container configuration from a submodule
  mkContainer =
    _name: cfg:
    {
      image = "${IMAGE}:${cfg.imageVersion}";
      autoStart = true;
      environment = lib.mkMerge [
      ];
      environmentFiles = [
      ];
      volumes = [
        "${cfg.TSsockLocation}:/var/run/tailscale/tailscaled.sock"
        "${cfg.volumeLocation}/data:/data"
        "${cfg.volumeLocation}/config:/config"
        "${cfg.volumeLocation}/config:/etc/caddy/"
        # "${(pkgs.writeTextFile {
        #   name = "${name}caddyfile";
        #   text = cfg.caddyfile;
        # })}:/etc/caddy/Caddyfile"
      ];
      extraOptions = [
        "--pull=always"
      ];
      user = "4000:4000";
    };
  mkTmpfilesRules = _name: cfg: [
    "d ${cfg.volumeLocation}/data 0755 4000 4000"
    "d ${cfg.volumeLocation}/config 0755 4000 4000"
  ];
in
{
  options.yomaq.pods = {
    "${NAME}" = mkOption {
      default = { };
      type = with types; attrsOf (submodule containerOpts);
      example = { };
      description = lib.mdDoc ''
        Additional tailscale containers to pair with container services to expose on the tailnet.
      '';
    };
  };
  config = mkIf (cfg != { }) {

    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) config.yomaq.pods."${NAME}"
    );
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer config.yomaq.pods."${NAME}";
  };
}
