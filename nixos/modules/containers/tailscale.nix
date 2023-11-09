{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    # import the container runtime configuration
    ./default.nix
    # import agenix and impermanance for encryption/ensure the key persists
    inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
  ];

  ### agenix secrets for container
  age.secrets.tailscale-envFile.file = ../../../secrets/tailscale-envFile.age;
  # specify which agenix key to use
  age.identityPaths = [ "/etc/nix/containers" ];
  # # make sure the key persists between boots
  environment.persistence."/nix/persistent".files = [
      { file = "/etc/nix/containers"; parentDirectory = { mode = "0700"; }; }
    ];


# make the directories where the volumes are stored
# it says "tmpfiles" but we don't add rules to remove the tmp file, so its... not tmp?
# https://discourse.nixos.org/t/creating-directories-and-files-declararively/9349
# storing volumes in the nix directory because we assume impermanance is wiping root
  systemd.tmpfiles.rules = [
    "d /nix/persistent/backup/containers/tailscale/data-lib 0755 root root"
    "d /nix/persistent/backup/containers/tailscale/dev-net-tun 0755 root root"
  ];


  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      environment = {
       "TS_HOSTNAME" =" tailnord";
       "TS_STATE_DIR"= "/var/lib/tailscale";
       "TS_EXTRA_ARGS" = "--advertise-exit-node";
       "TS_ACCEPT_DNS" = "true"
      };
      environmentFiles = [
        # need to set "TS_AUTHKEY=key" in agenix and import here
        config.age.secrets.tailscale-envFile.path
      ];
      volumes = [
        "/nix/persistent/backup/containers/tailscale/data-lib:/var/lib"
        "/nix/persistent/backup/containers/tailscale/dev-net-tun:/dev/net/tun"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };
  };
}

