### More of a template to be copied and customized to fit the specific needs of the computer
### Recommend placing in the computer's hosts folder


{ config, lib, pkgs, modulesPath, inputs, ... }:
let
  # Set to your disk name
  disk = "nvme0n1";
  disk2 = "nvme1n1";
  disk3 = "sda";
  disk4 = "sdb";
  # set hostID (8 random hex digits)
  hostID = "49e95c43";
  # ethernet kernel driver (run "lspci -v | grep -iA8 'network\|ethernet'")
  ethernetDriver = "igc";

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;

in
{
  imports =[];
  
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


                        # # may be needed in the future, currently don't see a way to setup ssh keys for
                        # # initrd users with this method, altho it is recommended on rebuild (on unstable)
                        # boot.initrd.systemd.users.root.shell = "/bin/cryptsetup-askpass";
                        # boot.initrd.systemd.enable = true;

  # setup initrd ssh to unlock the encripted drive
  boot.initrd.network.enable = true;
  boot.initrd.availableKernelModules = [ "${ethernetDriver}" ];
  boot.kernelParams = [ "ip=::::${hostName}-initrd::dhcp" ];
  boot.initrd.network.ssh = {
    enable = true;
    port = 22;
    shell = "/bin/cryptsetup-askpass";
    authorizedKeys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI" 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
      ];
    hostKeys = [ "/etc/ssh/initrd" ];
  };
  boot.initrd.secrets = {
    "/etc/ssh/initrd" = "/etc/ssh/initrd";
  };


  # Needed for agenix.
    # nixos-anywhere currently has issues with impermanence so agenix keys are lost during the install process.
    # as such we give /etc/ssh its own zfs dataset rather than using impermanence to save the keys when we wipe the root directory on boot
    # agenix needs the keys available before the zfs datasets are mounted, so we need this to make sure they are available.
 fileSystems."/etc/ssh".neededForBoot = true;
  # Needed for impermanence, because we mount /persist/save on /persist, we need to make sure /persist is mounted before /persist/save
  fileSystems."/persist".neededForBoot = true;

  # basic impermanence folders setup
  environment.persistence."${dontBackup}" = {
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

  # needed to use zfs
  networking.hostId = hostID;

  boot.initrd.postDeviceCommands =
       #wipe / and /var on boot
       lib.mkAfter ''
         zfs rollback -r zroot/root@empty
     '';

  # snapshots
  yomaq.sanoid.enable = true;
  services.sanoid = {
    datasets = {
      "zstorage/storage".useTemplate = [ "default" ];
    };
  };
    

  # Disco configuration.
  disko.devices = {
    disk = {
      one = {
        type = "disk";
        device = "/dev/${disk}";
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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted1";
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
      two = {
        type = "disk";
        device = "/dev/${disk2}";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted2";
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
      three = {
        type = "disk";
        device = "/dev/${disk3}";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted3";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key";
                content = {
                type = "zfs";
                pool = "zstorage";
                };
              };
            };
          };
        };
      };
      four = {
        type = "disk";
        device = "/dev/${disk4}";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted4";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key";
                content = {
                type = "zfs";
                pool = "zstorage";
                };
              };
            };
          };
        };
      };
    };



    zpool = {
      zstorage = {
        type = "zpool";
        mode = "mirror";
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
          storage = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/storage";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zstorage/storage@empty";
          };
        };
      };
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
          persistSave = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist/save";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zroot/persistSave@empty";
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
            options."com.sun:auto-snapshot" = "false";
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
