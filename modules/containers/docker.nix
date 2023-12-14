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