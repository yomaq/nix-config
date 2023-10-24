{ options, config, lib, pkgs, ... }:


# this is used in other places to allow modules to be dynamic to the primary user accounts on the machine
with lib;
{
  options.yomaq.primaryUser = {
    users = mkOption {
      type = types.listOf types.str;
      default = [ "admin" ];
      description = ''
        list Primary users for the computer
      '';
    };
  };
}