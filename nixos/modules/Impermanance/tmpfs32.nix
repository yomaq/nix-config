### More of a template to be copied and customized to fit the specific needs of the computer
### Recommend placing in the computer's hosts folder


{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =[
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
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

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = dev/sda;
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
          };
        };
      };
    };
  };
}