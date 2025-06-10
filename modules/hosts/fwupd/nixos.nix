{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.fwupd;
in
{
  options.yomaq.fwupd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom fwupd module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.fwupd.enable = true;
    # may look at scheduling tasks to check for updates and send ntfy notifications if updates are available.
  };
}
