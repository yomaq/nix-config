{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.suites.basics;
in
{
  config = lib.mkIf cfg.enable {
    yomaq = {
      glances.enable = true;
      monitorServices.enable = true;
    };
  };
}
