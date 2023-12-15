{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.network;
in
{

  config = mkIf cfg.basics {
    networking.networkmanager.enable = true;
  };
}