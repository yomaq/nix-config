{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  authorizedkeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
  ];
  cfg = config.yomaq.disks;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
in
{
  options.yomaq.disks = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom disk configuration
      '';
    };
    amReinstalling = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        am I reinstalling and want to save the storage pool + keep /persist/save unused so I can restore data
      '';
    };
    systemd-boot = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    initrd-ssh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      ethernetDrivers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          ethernet drivers to load: (run "lspci -v | grep -iA8 'network\|ethernet'")
        '';
      };
    };
    zfs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      hostID = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      root = {
        encrypt = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        disk1 = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            device name
          '';
        };
        disk2 = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            device name
          '';
        };
        reservation = lib.mkOption {
          type = lib.types.str;
          default = "20GiB";
          description = ''
            zfs reservation
          '';
        };
        mirror = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            mirror the zfs pool
          '';
        };
        impermanenceRoot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            wipe the root directory on boot
          '';
        };
      };
      storage = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        disks = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            device names
          '';
        };
        reservation = lib.mkOption {
          type = lib.types.str;
          default = "20GiB";
          description = ''
            zfs reservation
          '';
        };
        mirror = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            mirror the zfs pool
          '';
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.systemd-boot) {
      # setup systemd-boot
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })
    (lib.mkIf (cfg.enable && cfg.initrd-ssh.enable) {
      # setup initrd ssh to unlock the encripted drive
      boot.initrd.network.enable = true;
      boot.initrd.availableKernelModules = cfg.initrd-ssh.ethernetDrivers;
      boot.kernelParams = [ "ip=::::${hostName}-initrd::dhcp" ];
      boot.initrd.network.ssh = {
        enable = true;
        port = 22;
        shell = "/bin/cryptsetup-askpass";
        authorizedKeys = authorizedkeys;
        hostKeys = [ "/etc/ssh/initrd" ];
      };
      boot.initrd.secrets = {
        "/etc/ssh/initrd" = "/etc/ssh/initrd";
      };
    })
    (lib.mkIf cfg.enable {
      # basic impermanence folders setup
      environment.persistence."${dontBackup}" = {
        hideMounts = true;
        directories = [
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/etc/NetworkManager/system-connections"
        ];
      };
    })
    (lib.mkIf cfg.zfs.enable {
      networking.hostId = cfg.zfs.hostID;
      environment.systemPackages = [ pkgs.zfs-prune-snapshots ];
      boot = {
        # Newest kernels might not be supported by ZFS
        # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
        # ZFS does not support swapfiles, disable hibernate and set cache max
        kernelParams = [
          "nohibernate"
          "zfs.zfs_arc_max=17179869184"
        ];
        supportedFilesystems = [
          "vfat"
          "zfs"
        ];
        zfs = {
          devNodes = "/dev/disk/by-id/";
          forceImportAll = true;
          requestEncryptionCredentials = true;
        };
      };
      services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
      };
    })
    (lib.mkIf cfg.zfs.enable {
      disko.devices = {
        disk = lib.mkMerge [
          (lib.mkIf (cfg.zfs.storage.enable && !cfg.amReinstalling) (
            lib.mkMerge (
              map (diskname: {
                "${diskname}" = {
                  type = "disk";
                  device = "/dev/${diskname}";
                  content = {
                    type = "gpt";
                    partitions = {
                      luks = {
                        size = "100%";
                        content = {
                          type = "luks";
                          name = "stg${diskname}";
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
              }) cfg.zfs.storage.disks
            )
          ))
          ({
            one = lib.mkIf (cfg.zfs.root.disk1 != "") {
              type = "disk";
              device = "/dev/${cfg.zfs.root.disk1}";
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
                        "umask=0077"
                      ];
                    };
                  };
                  luks = lib.mkIf cfg.zfs.root.encrypt {
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
                  notluks = lib.mkIf (!cfg.zfs.root.encrypt) {
                    size = "100%";
                    content = {
                      type = "zfs";
                      pool = "zroot";
                    };
                  };
                };
              };
            };
            two = lib.mkIf (cfg.zfs.root.disk2 != "") {
              type = "disk";
              device = "/dev/${cfg.zfs.root.disk2}";
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
          })
        ];
        zpool = {
          zroot = {
            type = "zpool";
            mode = lib.mkIf cfg.zfs.root.mirror "mirror";
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
                  reservation = "${cfg.zfs.root.reservation}";
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
          zstorage = lib.mkIf (cfg.zfs.storage.enable && !cfg.amReinstalling) {
            type = "zpool";
            mode = lib.mkIf (cfg.zfs.storage.mirror) "mirror";
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
                  reservation = "${cfg.zfs.storage.reservation}";
                };
                type = "zfs_fs";
              };
              storage = {
                type = "zfs_fs";
                mountpoint = "/storage";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                };
              };
              persistSave = {
                type = "zfs_fs";
                mountpoint = "/storage/save";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                };
              };
              backups = lib.mkIf config.yomaq.syncoid.isBackupServer {
                type = "zfs_fs";
                mountpoint = "/backups";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                };
              };
            };
          };
        };
      };
      # Needed for agenix.
      # nixos-anywhere currently has issues with impermanence so agenix keys are lost during the install process.
      # as such we give /etc/ssh its own zfs dataset rather than using impermanence to save the keys when we wipe the root directory on boot
      # agenix needs the keys available before the zfs datasets are mounted, so we need this to make sure they are available.
      fileSystems."/etc/ssh".neededForBoot = true;
      # Needed for impermanence, because we mount /persist/save on /persist, we need to make sure /persist is mounted before /persist/save
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/persist/save".neededForBoot = true;
    })
    (lib.mkIf (cfg.zfs.root.impermanenceRoot) {
      boot.initrd.postResumeCommands =
        #wipe / and /var on boot
        lib.mkAfter ''
          zfs rollback -r zroot/root@empty
        '';
    })
  ];
}
