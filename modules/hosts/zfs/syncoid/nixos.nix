{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg =
    if config ? inventory.hosts."${config.networking.hostName}".syncoid then
      config.inventory.hosts."${config.networking.hostName}".syncoid
    else
      null;
  thisHost = config.networking.hostName;
  allSyncoidClients = lib.attrNames (
    lib.filterAttrs (
      hostName: hostConfig: lib.attrByPath [ "syncoid" "enable" ] false hostConfig == true
    ) config.inventory.hosts
  );
  syncoidClients = lib.remove config.networking.hostName allSyncoidClients;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.syncoid = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                enable zfs syncoid module
              '';
            };
            isBackupServer = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                will run syncoid and backup other nixos hosts
              '';
            };
            datasets = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "zroot/persistSave" ];
              description = ''
                list of datasets syncoid has access to on client
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg != null && cfg.enable) {
      services.syncoid.enable = true;
      # I believe I need to create the login shell as I am not using the default method of enabling ssh for the user (using tailscale ssh auth instead)
      users.users.syncoid.shell = pkgs.bash;
      # give syncoid user access to send and hold snapshots
      systemd.services = (
        lib.mkMerge (
          map (dataset: {
            "syncoid-zfs-allow-${(lib.replaceStrings [ "/" ] [ "-" ] "${dataset}")}" = {
              serviceConfig.ExecStart = "${lib.getExe pkgs.zfs} allow -u syncoid bookmark,snapshot,send,hold ${dataset}";
              wantedBy = [ "multi-user.target" ];
            };
          }) cfg.datasets
        )
      );
    })
    (lib.mkIf (cfg != null && cfg.isBackupServer) {
      services.syncoid = {
        enable = true;
        interval = "daily";
        commonArgs = [ "--no-sync-snap" ];
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
    {
      services.syncoid = lib.mkIf (cfg != null && cfg.isBackupServer) (
        lib.mkMerge (
          map (hostName: {
            commands = {
              "${hostName}Save" = {
                source = "syncoid@${hostName}:zroot/persistSave";
                target = "zstorage/backups/${hostName}";
                recvOptions = "c";
              };
            };
          }) syncoidClients
        )
      );
      services.sanoid = lib.mkIf (cfg != null && cfg.isBackupServer) (
        lib.mkMerge (
          map (hostName: {
            datasets."zstorage/backups/${hostName}" = {
              autosnap = false;
              autoprune = true;
              hourly = 0;
              daily = 14;
              monthly = 6;
              yearly = 1;
            };
          }) syncoidClients
        )
      );

      # backup monitoring service for all nixosHosts
      systemd.services = lib.mkIf (cfg != null && cfg.isBackupServer) (
        lib.mkMerge (
          map (hostName: {
            "syncoid-${hostName}Save" = {
              onSuccess = [ "syncoid-success-${hostName}.service" ];
              onFailure = [ "syncoid-fail-${hostName}.service" ];
            };
            "syncoid-success-${hostName}" = {
              script = ''
                ${lib.getExe pkgs.curl} -X POST \
                                https://azure-gatus.sable-chimaera.ts.net/api/v1/endpoints/backup_${hostName}/external\?success\=true\&error\= \
                                -H 'Authorization: Bearer ${hostName}'
              '';
            };
            "syncoid-fail-${hostName}" = {
              script = ''
                ${lib.getExe pkgs.curl} -X POST \
                                https://azure-gatus.sable-chimaera.ts.net/api/v1/endpoints/backup_${hostName}/external\?success\=false\&error\= \
                                -H 'Authorization: Bearer ${hostName}'
              '';
            };
          }) allSyncoidClients
        )
      );
    }
    (lib.mkIf config.yomaq.gatus.enable {
      yomaq.gatus.externalEndpoints =
        map
          (host: {
            name = "${host}";
            group = "backup";
            token = "${host}";
            alerts = [
              {
                type = "ntfy";
                failureThreshold = 3;
                description = "healthcheck failed";
              }
            ];
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.syncoid.enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          );
    })
  ];
}
