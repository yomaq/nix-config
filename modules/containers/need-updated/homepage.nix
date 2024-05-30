{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "homepage";
  IMAGE = "ghcr.io/gethomepage/homepage";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;


  settings = {
    title = "name";
    background = {
        blur = "sm"; # sm, "", md, xl... see https://tailwindcss.com/docs/backdrop-blur
        saturate = 50; # 0, 50, 100... see https://tailwindcss.com/docs/backdrop-saturate
        brightness = 50; # 0, 50, 75... see https://tailwindcss.com/docs/backdrop-brightness
        opacity = 50; # 0-100
    };
    theme = "dark"; # or light
    color = "stone";
    providers = {
        openweathermap = "openweathermapapikey";
        weatherapi = "weatherapiapikey";
    };
  };


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
      default = "${dontBackup}/containers/${NAME}";
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
      "d ${cfg.volumeLocation}/config 0755 4000 4000"
      # "f ${cfg.volumeLocation}/config/docker.yaml 755 4000 4000"
      # "f ${cfg.volumeLocation}/config/settings.yaml 755 4000 4000 - ${(pkgs.formats.yaml { }).generate "${NAME}Settings" settings}"
    ];
    virtualisation.oci-containers.containers = {
### main container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
          "PUID" = "4000";
          "PGID" = "4000";
        };
        environmentFiles = [
          # config.age.secrets."${NAME}EnvFile".path
        ];
        volumes = [
          "${cfg.volumeLocation}/config:/app/config"
          # "${cfg.volumeLocation}/config/docker.yaml:/app/config/docker.yaml"
          # "${cfg.volumeLocation}/config/settings.yaml:/app/config/settings.yaml"
        ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
        # user = "4000:4000";
      };
    };
    yomaq.pods.tailscaled."TS${NAME}".TSserve =  {"/" = "http://127.0.0.1:3000";};
  };
}