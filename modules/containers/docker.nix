{ pkgs, config, lib, inputs, ... }:
with lib;

let
  cfg = config.yomaq.docker;

in {
  options.yomaq.docker = {
    enable = mkOption {
      description = "Enable podman";
      type = types.bool;
      default = false;
    };
    traefik = mkOption {
      description = "Enable traefik for docker with tailscale tls certificates";
      type = types.bool;
      default = false;
    };
  };


  config = mkMerge [
    # enable and configure docker 
    (mkIf (cfg.enable) {
      virtualisation.oci-containers.backend = "docker";
      virtualisation = {
        docker = {
          enable = true;
          autoPrune.enable = true;

        };
      };
      environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
        directories = [
          "/var/lib/containers/storage"
        ];
      };
    })
    # enable and configure traefik
    (mkIf (cfg.traefik) {
      services.traefik = {
        package = inputs.self.packages.x86_64-linux.traefik-test;
        enable =true;
        group = "docker";
        staticConfigOptions = {
          global = {
            checkNewVersion = false;
            sendAnonymousUsage = false;
          };
          entryPoints = {
            http = {
              address = ":80";
              http = {
                redirections = {
                  entryPoint = {
                    to = "https";
                    scheme = "https";
                  };
                };
              };
            };
            https = {
              address = ":443";
            };
          };
          providers = {
            docker = {
              endpoint = "unix:///var/run/docker.sock";
              exposedByDefault = false;
            };
          };
          certificatesResolvers.tailscale.tailscale = {};
        };
      };
      environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
        hideMounts = true;
        directories = [
          "/var/lib/traefik"
        ];
      };
    })
  ];
}