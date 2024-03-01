{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.suites.foundation;
in
{
  options.yomaq.suites.foundation = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
      '';
    };
  };

  config = mkIf cfg.enable {
    yomaq = {
      agenix.enable = true;
      nixSettings.enable = true;
      tailscale.enable = true;
      network.basics = true;
    };
  };
}