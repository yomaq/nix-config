{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.network;
in
{
  options.yomaq.network = {
    basics  = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom nix settings
      '';
    };
  };
}