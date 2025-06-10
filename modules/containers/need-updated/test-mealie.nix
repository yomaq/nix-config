{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  ### Set container name and image
  NAME = "mealie";
  IMAGE = "ghcr.io/mealie-recipes/mealie";

  cfg = config.yomaq.pods.${NAME};
  inherit (config.yomaq.impermanence) backup;
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
    systemd.tmpfiles.rules = [
    ];
    virtualisation.oci-containers.containers = {
      ### main container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
          "ALLOW_SIGNUP" = "true";
        };
        environmentFiles = [
        ];
        volumes = [
        ];
        extraOptions = [
          "--pull=always"
          "--network=container:TS${NAME}"
        ];
      };
    };
    yomaq.pods.tailscaled."TS${NAME}" = {
      enable = true;
      TSserve = "http://127.0.0.1:9000";
    };
  };
}
