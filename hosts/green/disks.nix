### More of a template to be copied and customized to fit the specific needs of the computer
### Recommend placing in the computer's hosts folder


{ config, lib, pkgs, modulesPath, inputs, ... }:
let
  inherit (config.networking) hostName;
in
{
  imports =[];
  
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Needed for impermanance 
  # boot.initrd.systemd.enable = true;

  # setup initrd ssh to unlock the encripted drive
  boot.initrd.network.enable = true;
  boot.initrd.availableKernelModules = [ "e1000e" ];
  boot.kernelParams = [ "ip=dhcp" ];
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    shell = "/bin/cryptsetup-askpass";
    authorizedKeys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI" 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
      ];
    hostKeys = [ "/etc/ssh/${hostName}-initrd.key" ];
  };
  boot.initrd.secrets = {
    "/etc/ssh/${hostName}-initrd.key" = "/etc/ssh/${hostName}-initrd.key";
    "/etc/ssh/${hostName}-initrd.pub" = "/etc/ssh/${hostName}-initrd.pub";
  };
  boot.initrd.networkd.postCommands = lib.mkAfter ''/bin/ash'';
  # boot.initrd.systemd.users.root.shell = "/bin/cryptsetup-askpass";


  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
    ];
  };


# ### enable swap
#  swapDevices = [ {
#     device = "/nix/swapfile";
#     size = 4*1024;
#   } ];




  #boot.initrd.postDeviceCommands =
  #      #wipe / and /var on boot
  #      lib.mkAfter ''
  #        zfs rollback -r rpool/root@empty
  #    '';


  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "EFI";
              name = "ESP";
              size = "2048M";
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
            swap = {
              size = "8G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key";
                content = {
                type = "zfs";
                pool = "zroot";
                };
              };
            };
          };
        };
      };
    };
    # nodev = {
    #   "/" = {
    #     fsType = "tmpfs";
    #     mountOptions = [
    #       "defaults" "size=5G" "mode=755"
    #     ];
    #   };
    # };



    zpool = {
      zroot = {
        type = "zpool";
        #mode = "mirror";
        rootFsOptions = {
          canmount = "off";
          checksum = "edonr";
          compression = "zstd";
          dnodesize = "auto";
          mountpoint = "none";
          normalization = "formD";
          relatime = "on";
          "com.sun:auto-snapshot" = "false";
        };
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
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zroot/home@empty";
          };
          etcssh = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/etc/ssh";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zroot/etcssh@empty";
          };
          persist = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zroot/persist@empty";
          };
          nix = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "on";
              "com.sun:auto-snapshot" = "false";
            };
            postCreateHook = "zfs snapshot zroot/nix@empty";
          };
          root = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = ''
              zfs snapshot zroot/root@empty
            '';
          };
        };
      };
    };
  };
}

