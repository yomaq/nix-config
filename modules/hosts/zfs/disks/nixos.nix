{ options, config, lib, pkgs, inputs, ... }:

with lib;
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
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom disk configuration
      '';
    };
    amReinstalling = mkOption {
      type = types.bool;
      default = false;
      description = ''
        am I reinstalling and want to save the storage pool + keep /persist/save unused so I can restore data
      '';
    };
    systemd-boot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable systemd-boot
      '';
    };
     initrd-ssh = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          enable initrd ssh
        '';
      };
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          authorized keys for initrd ssh
        '';
      };
      ethernetDrivers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          ethernet drivers to load: (run "lspci -v | grep -iA8 'network\|ethernet'")
        '';
      };
     };
     zfs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          enable zfs
        '';
      };
      hostID = mkOption {
        type = types.str;
        default = "";
        description = ''
          host id for zfs
        '';
      };
      root = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            enable zfs root
          '';
        };
        encrypt = mkOption {
          type = types.bool;
          default = true;
          description = ''
            encrypt the zfs root
          '';
        };
        disk1 = mkOption {
          type = types.str;
          default = "";
          description = ''
            device name
          '';
        };
        disk2 = mkOption {
          type = types.str;
          default = "null";
          description = ''
            device name
          '';
        };
        reservation = mkOption {
          type = types.str;
          default = "20GiB";
          description = ''
            zfs reservation
          '';
        };
        mirror = mkOption {
          type = types.bool;
          default = false;
          description = ''
            mirror the zfs pool
          '';
        };
        impermanenceRoot = mkOption {
          type = types.bool;
          default = false;
          description = ''
            wipe the root directory on boot
          '';
        };
        impermanenceHome = mkOption {
          type = types.bool;
          default = false;
          description = ''
            wipe the home directory on boot
          '';
        };
      };
      storage = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            enable zfs root
          '';
        };
        disks = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            device names
          '';
        };
        reservation = mkOption {
          type = types.str;
          default = "20GiB";
          description = ''
            zfs reservation
          '';
        };
        mirror = mkOption {
          type = types.bool;
          default = false;
          description = ''
            mirror the zfs pool
          '';
        };
      };
    };
  };

  config = mkMerge [ 
    (mkIf (cfg.enable && cfg.systemd-boot) {
      # setup systemd-boot
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })
    (mkIf (cfg.enable && cfg.initrd-ssh.enable) {
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
    (mkIf cfg.enable {
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
    (mkIf cfg.zfs.enable {
      networking.hostId = cfg.zfs.hostID;
      environment.systemPackages = [pkgs.zfs-prune-snapshots];
      boot = {
        # Newest kernels might not be supported by ZFS
        kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
        # ZFS does not support swapfiles, disable hibernate and set cache max
        kernelParams = [
          "nohibernate"
          "zfs.zfs_arc_max=17179869184"
        ];
        supportedFilesystems = [ "vfat" "zfs" ];
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
    (mkIf cfg.zfs.root.enable {
      disko.devices = {
        disk = mkMerge [ 
          (mkIf (cfg.zfs.storage.disks != [] && !cfg.amReinstalling) (mkMerge (map ( diskname: {
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
                  # zfs = {
                  #   size = "100%";
                  #   content = {
                  #     type = "zfs";
                  #     pool = "zstorage";
                  #   };
                  # };
                };
              };
            };
          })cfg.zfs.storage.disks)))
          ({one = {
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
                luks = mkIf cfg.zfs.root.encrypt {
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
                notluks = mkIf (!cfg.zfs.root.encrypt) {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "zroot";
                  };
                };
              };
            };
          };
          two = mkIf (cfg.zfs.root.disk2 != "null") {
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
          };})];
        zpool = {
          zroot = {
            type = "zpool";
            mode = mkIf cfg.zfs.root.mirror "mirror";
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
          zstorage = mkIf (cfg.zfs.storage.enable && !cfg.amReinstalling) {
            type = "zpool";
            mode = mkIf (cfg.zfs.storage.mirror) "mirror";
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
                  # #encryption
                  # encryption = "aes-256-gcm";
                  # keyformat = "passphrase";
                  # keylocation = "file:///tmp/secret.key";
                };
              };
              backups = mkIf config.yomaq.syncoid.isBackupServer {
                type = "zfs_fs";
                mountpoint = "/backups";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                  # #encryption
                  # encryption = "aes-256-gcm";
                  # keyformat = "passphrase";
                  # keylocation = "file:///tmp/secret.key";
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
    (mkIf (cfg.zfs.root.enable && cfg.zfs.root.impermanenceRoot) {
      boot.initrd.postDeviceCommands =
        #wipe / and /var on boot
        lib.mkAfter ''
          zfs rollback -r zroot/root@empty
      '';
    })
    (mkIf (cfg.zfs.root.enable && cfg.zfs.root.impermanenceHome) {
      #wipe /home on boot
      boot.initrd.postDeviceCommands =
        lib.mkAfter ''
          zfs rollback -r zroot/home@empty
      '';
    })
  ];
}