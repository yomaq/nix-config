{ options, config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.yomaq.agenix;
in
{
  options.yomaq.agenix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom agenix module
      '';
    };
  };
}