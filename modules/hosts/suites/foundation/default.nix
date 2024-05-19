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
      zsh.enable =true;
      agenix.enable = true;
      nixSettings.enable = true;
      tailscale.enable = true;
      network.basics = true;
      initrd-tailscale.enable = true;
    };
  };
}