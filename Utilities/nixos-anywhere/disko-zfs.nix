### Needed hardware configuration to wipe root
  #boot.initrd.postDeviceCommands =
  #      #wipe / and /var on boot
  #      lib.mkAfter ''
  #        zfs rollback -r rpool/root@empty
  #    '';




{ config, lib, pkgs, inputs, ... }:
{
  imports =
    [
      inputs.disko.nixosModules.disko
      ./zfs.nix
    ];

  disko.devices = {
    disk = {
      # Boot drive
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            #boot = {
            #  size = "1M";
            #  type = "EF02"; # for grub MBR
            #};
            ESP = {
              label = "EFI";
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    ### Add additional disks
    #  disk1 = {
    #    type = "disk";
    #    device = builtins.elemAt disks 1;
    #    content = {
    #      type = "gpt";
    #      partitions = {
    #        zfs = {
    #          size = "100%";
    #          content = {
    #            type = "zfs";
    #            pool = "zroot";
    #          };
    #        };
    #      };
    #    };
    #  };
    };
    zpool = {
      zroot = {
        type = "zpool";
        #mode = "mirror";
        rootFsOptions = {
          canmount = "off";
          checksum = "edonr";
          compression = "zstd";
          dnodesize = "auto";
          encryption = "aes-256-gcm";
          # if you want to use the key for interactive login be sure there is no trailing newline
          # for example use `echo -n "password" > /tmp/secret.key`
          keylocation = "file:///tmp/disk-1.key";
          keyformat = "passphrase";
          mountpoint = "none";
          normalization = "formD";
          relatime = "on";
          "com.sun:auto-snapshot" = "false";
        };
        postCreateHook = ''
          zfs set keylocation="prompt" $name;
        '';
        options = {
          ashift = "12";
          autotrim = "on";
        };


        datasets = {
          # zfs uses cow free space to delete files when the disk is completely filled
          reserved = {
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "5GiB";
            };
            type = "zfs_fs";
          };
          home = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
            options."com.sun:auto-snapshot" = "true";
            postCreateHook = "zfs snapshot zroot/home@empty";
          };
          persist = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
            options."com.sun:auto-snapshot" = "true";
            postCreateHook = "zfs snapshot zroot/persist@empty";
          };
          nix = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "on";
              "com.sun:auto-snapshot" = "true";
            };
            postCreateHook = "zfs snapshot zroot/nix@empty";
          };
          root = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = ''
              zfs snapshot zroot/root@empty
              zfs snapshot zroot/root@lastboot
            '';
          };
        };
      };
    };
  };
}
