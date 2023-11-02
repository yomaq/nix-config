{ options, config, lib, pkgs, ... }:
let
  cfg = config.yomaq._1password;
in
{
  options.yomaq._1password = {
    enable = with lib; mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom 1password module
      '';
    };
  };

 config =
   (lib.optionalAttrs (cfg.enable && pkgs.system == "x86_64-linux") {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = config.yomaq.primaryUser.users;
    };
   }) //
   (lib.optionalAttrs (cfg.enable && pkgs.system == "aarch64-darwin") {
    homebrew.casks = [
      "1password"
      "1password-cli"
    ];
   });
}