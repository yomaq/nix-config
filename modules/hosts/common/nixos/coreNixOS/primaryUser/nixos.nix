{ options, config, lib, pkgs, ... }:


# this is used in other places to allow modules to be dynamic to the primary user accounts on the machine, is used frequently in other modules
# may eventually expand to configure everything related to user accounts
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