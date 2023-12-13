
### service that creates podman pods taken from the nixos discord from a deleted user
# https://discord.com/channels/568306982717751326/1138571694466936852/1138826346345279609

{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.yomaq.podman;

in {
  options.yomaq.podman = {
    enable = mkOption {
      description = "Enable podman";
      type = types.bool;
      default = false;
    };
  };


  config = mkIf (cfg.enable) {
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

  };
}