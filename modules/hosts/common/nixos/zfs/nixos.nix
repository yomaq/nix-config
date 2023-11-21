{ config, pkgs, lib, ... }:
# Other useful settings come from srvos's zfs module



### mostly copied from another user, but I don't remember who
### the settings mostly look good. Not sure about how needed the cache max is, but its all working good so far.
{
  config = lib.mkIf config.boot.zfs.enabled {
    environment.systemPackages = [
      pkgs.zfs-prune-snapshots
    ];
    
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
    # Don't let zfs mount the the datasets, because of legacy mounting
    #systemd.services.zfs-mount.enable = false;
  };
}
