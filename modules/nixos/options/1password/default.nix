{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq._1password;
in
{
  options.yomaq._1password = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom 1password module
      '';
    };
  };

  config = mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = config.yomaq.primaryUser.users;
    };
  };

}