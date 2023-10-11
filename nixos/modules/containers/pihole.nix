{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    # import the container runtime configuration
    ./default.nix
    # import agenix and impermanance for encryption/ensure the key persists
    ../../../secrets/agenix.nix #you can only import agenix into an output once, so rather than importing it directly we have to import it into a module, and import that module into every other module we need it in.
  ];

  ### agenix secrets for container(s)
  age.secrets.pihole-envFile.file = ../../../secrets/pihole-envFile.age;
  age.secrets.tailscale-envFile.file = ../../../secrets/tailscale-envFile.age;
  # Make sure the correct agenix decription keys are set on the host



# make the directories where the volumes are stored
# it says "tmpfiles" but we don't add rules to remove the tmp file, so its... not tmp?
# https://discourse.nixos.org/t/creating-directories-and-files-declararively/9349
# storing volumes in the nix directory because we assume impermanance is wiping root
  systemd.tmpfiles.rules = [
    "d /nix/persistent/backup/containers/pihole/etc-pihole 0755 root root"
    "d /nix/persistent/backup/containers/pihole/etc-dnsmasq.d 0755 root root"
    "d /nix/persistent/backup/containers/tailscale/data-lib 0755 root root"
    "d /nix/persistent/backup/containers/tailscale/dev-net-tun 0755 root root"
  ];

  # Expose nixOS host ports
  networking.firewall.allowedTCPPorts = [80 53];
  networking.firewall.allowedUDPPorts = [53];

  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      environment = {
        "TZ" = "America/Chicago";
      };
      environmentFiles = [
        # need to set "WEBPASSWORD=password" in agenix and import here
        config.age.secrets.pihole-envFile.path
      ];
      volumes = [
        "/nix/persistent/backup/containers/pihole/etc-pihole:/etc/pihole"
        "/nix/persistent/backup/containers/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=container:tailscale-for-pihole"
      ];
    };
    tailscale-for-pihole = {
      image = "tailscale/tailscale:latest";
      autoStart = true;
      ports = [ "53:53/tcp" "53:53/udp" "80:80/tcp" ];
      environment = {
       "TS_HOSTNAME" =" tailnord";
       "TS_STATE_DIR"= "/var/lib/tailscale";
       "TS_EXTRA_ARGS" = "--exit-node _______________";
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