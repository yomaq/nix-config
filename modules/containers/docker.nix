{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.yomaq.docker;

in
{
  options.yomaq.docker = {
    enable = lib.mkOption {
      description = "Enable docker";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    virtualisation.oci-containers.backend = "docker";
    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
        # adding this because adding a bridge network to my docker hosts seems to ruin the dns settings, ignoring the hosts's dns server and ALWAYS adding the bridge network's router's dns server.
        # the above only applies to tailscale containers in userspace network mode
        # for some reason log.tailscale.io fails if I try to point to my normal tailscale dns server, this issues only just started occuring and idk why, so I point to a generic dns server.
        # hopfully https://github.com/tailscale/tailscale/issues/11372 will be fixed soon and I can make all containers use tun and skip userspace.
        extraOptions = "--dns 100.100.100.100 --dns 9.9.9.9";
      };
    };
    environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
      directories = [ "/var/lib/containers/storage" ];
    };
    users = {
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
