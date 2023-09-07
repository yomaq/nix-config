{ ... }:
{  
  disk = {
    main = {
      type = "disk";
      device = /dev/sda;
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
  };
  zpool = {
    zroot = {
      type = "zpool";
      mode = "mirror";
      rootFsOptions = {
        compression = "zstd";
        "com.sun:auto-snapshot" = "false";
      };
      #mountpoint = "";
      postCreateHook = "zfs snapshot zroot@blank";

      datasets = {
        #zfs_fs = {
        #  type = "zfs_fs";
        #  mountpoint = "/zfs_fs";
        #  options."com.sun:auto-snapshot" = "true";
        #};
        encrypted = {
          type = "zfs_fs";
          options = {
            mountpoint = "none";
            encryption = "aes-256-gcm";
            keyformat = "passphrase";
            keylocation = "file:///tmp/disk-1.key";
          };
          # use this to read the key during boot
          postCreateHook = ''
            zfs set keylocation="prompt" "zroot/$name";
          '';
        };
        "encrypted/test" = {
          type = "zfs_fs";
          mountpoint = "/";
          #postCreateHook = "zfs snapshot zroot/encripted/test@blank";
        };
      };
    };
  };
}
