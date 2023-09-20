{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =[
    inputs.impermanence.nixosModules.impermanence
  ];
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      { file = "/etc/nix/id_rsa"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
    #users.example = {
    #  directories = [];
    #  files = [];
    #};
  };


### enable swap
 swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 32*1024;
  } ];

### Mount root as tmpfs
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=28G" "mode=755" ];
  };
}