{ pkgs, config, lib, inputs, ... }:
with lib;

let
  cfg = config.yomaq.docker;

in {
  options.yomaq.docker = {
    enable = mkOption {
      description = "Enable docker";
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
        extraOptions = "--dns 100.100.100.100";
      };
    };
    environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
      directories = [
        "/var/lib/containers/storage"
      ];
    };
    users= {
      users.docker = {
        isNormalUser = true;
        uid = 4000;
      };
      groups.dockeruser = {
        gid = 4000;
        members = [ "docker" ];
      };
    };
  };
}