{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "dufs";
  IMAGE = "docker.io/sigoden/dufs";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;

in
{
  options.yomaq.pods.${NAME} = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom ${NAME} container module
      '';
    };
    agenixSecret = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/${NAME}EnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
    volumeLocation = mkOption {
      type = types.str;
      default = "${backup}/containers/${NAME}";
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
  };

  config = mkIf cfg.enable {
    ### agenix secrets for container
    # age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;

    systemd.tmpfiles.rules = [
      # main container
      "d ${cfg.volumeLocation}/data 0755 4000 4000"
    ];
    virtualisation.oci-containers.containers = {
### main container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environmentFiles = [
          # config.age.secrets."${NAME}EnvFile".path
        ];
        # environment = {
        #   "PUID" = "4000";
        #   "PGID" = "4000";
        # };
        volumes = [
          "${cfg.volumeLocation}/data:/data"
        ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
        user = "4000:4000";
        cmd = ["/data" "-A"];
      };
    };
    yomaq.pods.tailscaled."TS${NAME}" = {
      TSserve =  {"/" = "http://127.0.0.1:5000";};
      tags = ["tag:generichttps"];
    };

    yomaq.homepage.groups.services.services = [{
      "${NAME}" = {
        icon = "si-affinityphoto";
        href = "https://${hostName}-${NAME}.${tailnetName}.ts.net";
      };
    }];
  };
}