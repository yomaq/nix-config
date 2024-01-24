{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.suites.basics;
in
{
  imports = [
  ];
  config = mkIf cfg.enable {
    yomaq = {
      skhd.enable = true;
    };
  };
}