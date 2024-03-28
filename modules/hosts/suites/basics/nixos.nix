{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.suites.basics;
in
{
  config = mkIf cfg.enable {
    yomaq = {
      glances.enable = true;
    };
  };
}