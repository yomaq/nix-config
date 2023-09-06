{ disks ? [ "/dev/sda" ], inputs, ... }:
{
  imports =
    [ 
      inputs.agenix.nixosModules.default
    ];

  #age.identityPaths = [ "/home/carln/.ssh/agenix" ];
  age.secrets.zfs.file = ../../secrets/zfs.age;
  
  disk = {
    main = {
      type = "disk";
      device = builtins.elemAt disks 0;
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
      mountpoint = "none";
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
            keylocation = config.age.secrets.zfs.path;
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
          "com.sun:auto-snapshot" = "false";
        };
      };
    };
  };
}