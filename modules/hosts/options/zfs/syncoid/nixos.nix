{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.syncoid;
  thisHost =  config.networking.hostName;
  allNixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
  nixosHosts = builtins.filter (host: host != thisHost) allNixosHosts;
in
{
  options.yomaq.syncoid = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        enable zfs syncoid module
      '';
    };
    isBackupServer = mkOption {
      type = types.bool;
      default = false;
      description = ''
        will run syncoid and backup other nixos hosts
      '';
    };
  };

  config = ( mkIf config.yomaq.sanoid.enable {
    # enable syncoid by default on all systems
    services.syncoid.enable = true;
  # backup all nixos hosts that are not the backup server and have syncoid enabled
  }) // (mkIf config.yomaq.syncoid.isBackupServer (map ( hostName: optionalAttrs inputs.self.nixosConfigurations.${hostName}.config.syncoid.enable {
    services.syncoid = {
      commands = {
        "${hostName}Save" = {
        source = "syncoid@${hostName}:zpool/persistSave";
        target = "zstorage/backups/${hostName}Save";
        rcvOptions = "c";
        };
      };
        "${thisHost}Save" = {
          source = "zpool/persistSave";
          target = "zstorage/backups/${thisHost}Save";
          rcvOptions = "c";
        };
    };
    services.sanoid = {
      datasets."zstorage/backups/${hostName}Save" = {
          autosnap = false;
          autoprune = true;
          hourly = 0;
          daily = 14;
          monthly = 6;
          yearly = 1;
      };
    };
  }) nixosHosts
  # backup the backup server's PersistSave dataset
  ) // (mkIf config.yomaq.syncoid.isBackupServer {
    services.syncoid = {
      enable = true;
      interval = "daily";
      commands."${thisHost}Save" = {
        source = "zpool/persistSave";
        target = "zstorage/backups/${thisHost}Save";
        rcvOptions = "c";
      };
    };
    services.sanoid = {
      datasets."zstorage/backups/${thisHost}Save" = {
          autosnap = false;
          autoprune = true;
          hourly = 0;
          daily = 14;
          monthly = 6;
          yearly = 1;
      };
    };
  }));
}