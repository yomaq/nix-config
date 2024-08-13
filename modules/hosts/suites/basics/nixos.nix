{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.suites.basics;
in
{
  config = lib.mkIf cfg.enable {
    yomaq = {
      glances.enable = true;
    };
  };
}
