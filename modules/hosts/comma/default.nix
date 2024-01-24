{ options, config, lib, pkgs, ... }:
let
  cfg = config.yomaq.comma;
in
{
  options.yomaq.comma = {
    enable = with lib; mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom comma module
      '';
    };
  };
}