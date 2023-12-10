
### service that creates podman pods taken from the nixos discord from a deleted user
# https://discord.com/channels/568306982717751326/1138571694466936852/1138826346345279609

{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.yomaq.podman;

  podOptions = { name, ... }: {
    options = {
      name = mkOption {
        description = "Name of pod to create";
        type = types.str;
        default = "${name}-pod";
      };
      wantedBy = mkOption {
        description = "What systemd services require this pod";
        type = with types; listOf str;
        default = [];
        example = [ "podman-pod-redis.service" "podman-pod.service" ];
      };
      ports = mkOption {
        description = "List of ports to forward from the container to host";
        type = with types; listOf str;
        default = [];
        example = [ "2020:8000" "4000:8001" ];
      };
    };
  };

  toSystemdServiceConfig = serviceName: opts: {
    serviceConfig.Type = "oneshot";
    wantedBy = opts.wantedBy;
    script = concatStringsSep " \\\n  " ([
      "${pkgs.podman}/bin/podman pod exists ${opts.name} ||"
      "${pkgs.podman}/bin/podman pod create"
      "--name=${opts.name}"
    ] ++ map (p: "-p ${concatStrings [ "0.0.0.0:" p ] }") opts.ports );
  };
in {
  options.yomaq.podman = {
    enable = mkOption {
      description = "Enable podman";
      type = types.bool;
      default = true;
    };
    pods = mkOption {
      description = "List of pods to create";
      type = with types; attrsOf (submodule podOptions);
      example = {
        minecraft = {
          wantedBy = [ "podman-minecraft.service" "podman-dbforsomereason.service" ];
          # ports exposed to the host
          ports = [ "2020:8000" "4000:8001" ];
        }; 
      };
    };
  };


  config = mkIf (cfg.enable) {
    virtualisation.oci-containers.backend = "podman";
    virtualisation = {
      podman = {
        enable = true;
        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };
    environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
      directories = [
        "/var/lib/containers/storage"
      ];
    };



    systemd.services = mapAttrs toSystemdServiceConfig cfg.pods;
  };
}