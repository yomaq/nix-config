{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.suites.foundation;
in
{
  config = lib.mkIf cfg.enable {
    yomaq = {
      macosSettings.enable = true;
    };
  };
}
