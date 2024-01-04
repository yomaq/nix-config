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
}