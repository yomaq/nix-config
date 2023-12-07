{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.syncoid;
  thisHost =  config.networking.hostName;
  # nixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
  nixosHosts = ["test" "test2"];


  configToMap = (mkIf config.yomaq.syncoid.isBackupServer && !builtins.elem hostName cfg.exclude {
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
  });
  mappedConfig = builtins.map (hostName: configToMap) nixosHosts;
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
      default = [ "${thisHost}" ];
      description = ''
        exclude these hosts from being backed up
      '';
    };
  };
  config = mkMerge [
    mappedConfig
    (mkIf config.yomaq.sandoid.enable {services.syncoid.enable = true;})
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
    })];
}