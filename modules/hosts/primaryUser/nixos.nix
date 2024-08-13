{
  options,
  config,
  lib,
  pkgs,
  ...
}:

# this is used in other places to allow modules to be dynamic to the primary user accounts on the machine, is used frequently in other modules
# may eventually expand to configure everything related to user accounts
{
  options.yomaq.primaryUser = {
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "admin" ];
      description = ''
        list Primary users for the computer
      '';
    };
  };

  config = {
    # pulled from https://github.com/nix-community/srvos/blob/main/nixos/common/sudo.nix

    # Only allow members of the wheel group to execute sudo by setting the executable’s permissions accordingly. This prevents users that are not members of wheel from exploiting vulnerabilities in sudo such as CVE-2021-3156.
    security.sudo.execWheelOnly = true;
    # Don't lecture the user. Less mutable state.
    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';
  };
}
