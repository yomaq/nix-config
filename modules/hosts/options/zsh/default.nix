{ options, config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.yomaq.zsh;
in
{
  options.yomaq.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom zsh module
      '';
    };
  };
}