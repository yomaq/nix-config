{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.suites.foundation;
in
{
  config = mkIf cfg.enable {
    yomaq = {
      macosSettings.enable = true;
      homebrew.enable = true;
    };
  };
}