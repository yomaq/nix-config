{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.sanoid;
in
{
  options.yomaq.sanoid = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom sanoid, zfs-snapshot module
      '';
    };
    
  };

  config = mkIf cfg.enable {
    services.sanoid = {
      enable = true;
      templates = {
        default = {
          autosnap = true;
          autoprune = true;
          hourly = 8;
          daily = 14;
          monthly = 6;
          yearly = 1;
        };
      };
    };
  };
}