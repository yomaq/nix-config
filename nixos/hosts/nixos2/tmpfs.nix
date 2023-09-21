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
    ];
    files = [
      { file = "/etc/ssh/agenix"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
    #users.example = {
    #  directories = [];
    #  files = [];
    #};
  };


### enable swap
 swapDevices = [ {
    device = "/nix/swapfile";
    size = 4*1024;
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
    ### use either boot or ESP
            boot = {
             size = "1M";
             type = "EF02"; 
            };
            # ESP = {
            #   label = "EFI";
            #   name = "ESP";
            #   size = "512M";
            #   type = "EF00";
            #   content = {
            #     type = "filesystem";
            #     format = "vfat";
            #     mountpoint = "/boot";
            #     mountOptions = [
            #       "defaults"
            #     ];
            #   };
            # };
            nix = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
              };
            };
          };
        };
      };
    };
  };
}