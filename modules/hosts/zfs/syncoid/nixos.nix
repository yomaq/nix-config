{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.syncoid;
  thisHost =  config.networking.hostName;
  allNixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
  nixosHosts = lists.subtractLists (cfg.exclude ++ [thisHost]) allNixosHosts;
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
      default = [];
      description = ''
        exclude hosts from backup
      '';
    };
  };
  config = mkMerge [
    (mkIf config.yomaq.syncoid.enable {
      services.syncoid.enable = true;
      # I believe I need to create the login shell as I am not using the default method of enabling ssh for the user (using tailscale ssh auth instead)
      users.users.syncoid.shell = pkgs.bash;
    })
    (mkIf config.yomaq.syncoid.isBackupServer {
      services.syncoid = {
        enable = true;
        interval = "daily";
        commands."${thisHost}Save" = {
          source = "zroot/persistSave";
          target = "zstorage/backups/${thisHost}";
          recvOptions = "c";
        };
      };
      services.sanoid = {
        datasets."zstorage/backups/${thisHost}" = {
            autosnap = false;
            autoprune = true;
            hourly = 0;
            daily = 14;
            monthly = 6;
            yearly = 1;
        };
      };
    })    
    {services.syncoid = mkIf config.yomaq.syncoid.isBackupServer (mkMerge (map ( hostName: {
        commands = {
          "${hostName}Save" = {
          source = "syncoid@${hostName}:zroot/persistSave";
          target = "zstorage/backups/${hostName}";
          recvOptions = "c";
          };
        };
      })nixosHosts));
      services.sanoid = mkIf config.yomaq.syncoid.isBackupServer (mkMerge (map ( hostName: {
        datasets."zstorage/backups/${hostName}" = {
            autosnap = false;
            autoprune = true;
            hourly = 0;
            daily = 14;
            monthly = 6;
            yearly = 1;
        };
      })nixosHosts));
    }
  ];
}
