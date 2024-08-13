{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq._1password;
in
{
  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = config.yomaq.primaryUser.users;
    };
  };
}
