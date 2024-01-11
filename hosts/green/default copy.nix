{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.suites.basics;
in
{
  imports = [
  ];
  options.yomaq.test = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
      '';
    };
    cowsay123 = mkOption {
      type = types.string;
      default = "cowsay";
      description = "";
    };
  };
}