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
    physicalInterfaceName  = mkOption {
      type = types.str or types.null;
      default = null;
      description = ''
        physical interface name - used for useBr0 option bellow
      '';
    };
    useBr0  = mkOption {
      type = types.bool;
      default = false;
      description = ''
        use a bridge, for nixos containers / vms
      '';
    };
  };
}