{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    # import the container runtime configuration
    ./default.nix
    # import agenix and impermanance for encryption/ensure the key persists
    ../../../secrets/agenix.nix
    inputs.impermanence.nixosModules.impermanence
  ];

  ### agenix secrets for container
  age.secrets.encrypt.file = ../../../secrets/encrypt.age;
  # specify which agenix key to use
  age.identityPaths = [ "/home/carln/.ssh/agenix" ];
  # # make sure the key persists between boots
  environment.persistence."/nix/persistent".files = [
      { file = "/home/carln/.ssh/agenix"; parentDirectory = { mode = "0700"; }; }
    ];


# make the directories where the volumes are stored
# it says "tmpfiles" but we don't add rules to remove the tmp file, so its... not tmp?
# https://discourse.nixos.org/t/creating-directories-and-files-declararively/9349
# storing volumes in the nix directory because we assume impermanance is wiping root
  systemd.tmpfiles.rules = [
    "d /nix/persistent/backup/containers/pihole/etc-pihole 0755 root root"
    "d /nix/persistent/backup/containers/pihole/etc-dnsmasq.d 0755 root root"
  ];

  networking.firewall.allowedTCPPorts = [80 53];
  networking.firewall.allowedUDPPorts = [53];

  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      ports = [ "53:53/tcp" "53:53/udp" "80:80/tcp" ];
      environment = {
        "TZ" = "America/Chicago";
        #"WEBPASSWORD" = "test";
        "WEBPASSWORD_FILE" = config.age.secrets.encrypt.path;
      };
      # environmentFiles = [
      # ];
      volumes = [
        "/nix/persistent/backup/containers/pihole/etc-pihole:/etc/pihole"
        "/nix/persistent/backup/containers/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=host"
      ];
    };
  };
}