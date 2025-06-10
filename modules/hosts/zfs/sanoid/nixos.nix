{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.sanoid;
in
{
  options.yomaq.sanoid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        enable custom sanoid, zfs-snapshot module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.sanoid = {
      enable = true;
      templates = {
        default = {
          autosnap = true;
          autoprune = true;
          hourly = 8;
          daily = 1;
          monthly = 1;
          yearly = 1;
        };
      };
      datasets =
        {
          "zroot/persist".useTemplate = [ "default" ];
          "zroot/persistSave".useTemplate = [ "default" ];
        }
        // lib.optionalAttrs (config.yomaq.disks.zfs.storage.enable && !config.yomaq.disks.amReinstalling) {
          "zstorage/storage".useTemplate = [ "default" ];
          "zstorage/persistSave".useTemplate = [ "default" ];
        };
    };
  };
}
