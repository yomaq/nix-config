{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.syncoid;
  thisHost =  config.networking.hostName;
  allNixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
  #allNixosHosts = ["test" "test2" "test3" "test4"];
  #exclude = ["azure"];
  nixosHosts = lists.subtractLists cfg.exclude allNixosHosts;

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
    exclude = mkOption {
      type = types.listOf types.str;
      default = ["azure"];
      description = ''
        exclude hosts from backup
      '';
    };
  };
  config = mkMerge [
    (mkIf config.yomaq.syncoid.enable {services.syncoid.enable = true;})
    (mkIf config.yomaq.syncoid.isBackupServer {
      services.syncoid = {
        enable = true;
        interval = "daily";
        commands."${thisHost}Save" = {
          source = "zpool/persistSave";
          target = "zstorage/backups/${thisHost}Save";
          recvOptions = "c";
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
    })
    (mkIf config.yomaq.syncoid.isBackupServer (mkMerge (map ( hostName: {
      services.syncoid = {
        commands = {
          "${hostName}Save" = {
          source = "syncoid@${hostName}:zpool/persistSave";
          target = "zstorage/backups/${hostName}Save";
          recvOptions = "c";
          };
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
    })nixosHosts)))];
}