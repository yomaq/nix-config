{ config, lib, pkgs, modulesPath, inputs, ... }:
{
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
  environment.persistence."${config.yomaq.impermanence.dontbackup}" = {
    directories = [
      "/var/lib/containers/storage"
    ];
  };
}