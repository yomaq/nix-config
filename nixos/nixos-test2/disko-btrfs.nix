{ config, lib, pkgs, inputs, ... }:
{
  imports =
    [
      inputs.disko.nixosModules.disko
      inputs.agenix.nixosModules.default
    ];


  age.identityPaths = [ "/etc/ssh/agenix" ];
  age.secrets.encrypt.file = ../../secrets/encrypt.age;


  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = "/dev/sda";
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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                extraOpenArgs = [ "--allow-discards" ];
                # if you want to use the key for interactive login be sure there is no trailing newline
                # for example use `echo -n "password" > /tmp/secret.key`
                settings.keyFile = "/tmp/disk-1.key";
                ### I tried passing the key in like this:
                ### settings.keyFile = "/run/agenix/encrypt";
                ### So that the key would always be loaded in by agenix regardless of Disko does.
                ### However when disko tries to load at that location it fails as the location doesnt exist.
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}