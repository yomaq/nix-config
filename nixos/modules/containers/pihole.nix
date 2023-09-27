{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =[
    ./default.nix
    inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
  ];

  ### agenix secret containing the password in format:
  ### WEBPASSWORD: 'set a secure password here or it will be random'
  age.secrets.pihole.file = ../../../secrets/pihole.age;
  # specify which agenix key to use
  age.identityPaths = [ "/etc/ssh/containers" ];
  # make sure the key persists between boots
  environment.persistence."/nix/persistent".files = [
      { file = "/etc/nix/containers"; parentDirectory = { mode = "0700"; }; }
    ];


  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      ports = [ "53:53/tcp" "53:53/udp" "80:80/tcp" ];
      environment = {
        TZ = "America/Chicago";
      };
      environmentFiles = [
        # agenix secret created above
        config.age.secrets.pihole.path
      ];
      volumes = [
        "/nix/containers/pihole/etc-pihole:/etc/pihole"
        "/nix/containers/pihole//etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
    };
  };
}