{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.suites.foundation;
in
{
  config = lib.mkIf cfg.enable {
    yomaq = {
      initrd-tailscale.enable = true;
    };
  };
}
