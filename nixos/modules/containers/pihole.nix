{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    ./default.nix
    #inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
  ];

  # ### agenix secret containing the password in format:
  # ### WEBPASSWORD: 'set a secure password here or it will be random'
  # age.secrets.encrypt.file = ../../../secrets/encrypt.age;
  # # specify which agenix key to use
  # age.identityPaths = [ "/home/carln/.ssh/agenix" ];
  # # make sure the key persists between boots
  # environment.persistence."/nix/persistent".files = [
  #     { file = "/etc/nix/containers"; parentDirectory = { mode = "0700"; }; }
  #   ];


# make the directories where the volumes are stored
# it says "tmpfiles" but we don't add rules to remove the tmp file, so its... not tmp?
# https://discourse.nixos.org/t/creating-directories-and-files-declararively/9349
# storing volumes in the nix directory because we assume impermanance is wiping root
# and it makes sense to keep container storage separate from the default persistent folder
  systemd.tmpfiles.rules = [
    "d /nix/containers/pihole/etc-pihole 0755 root root"
    "d /nix/containers/pihole//etc-dnsmasq.d 0755 root root"
  ];


  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      ports = [ "53:53/tcp" "53:53/udp" "80:80/tcp" ];
      environment = {
        "TZ" = "America/Chicago";
        "WEBPASSWORD" = "test";
      };
      # environmentFiles = [
      #   # agenix secret created above
      #   config.age.secrets.encrypt.path
      # ];
      volumes = [
        "/nix/containers/pihole/etc-pihole:/etc/pihole"
        "/nix/containers/pihole//etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=host"
      ];
    };
  };
}