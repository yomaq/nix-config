{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.suites.container;
in
{
  options.yomaq.suites.container = {
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
    };
    networking.useHostResolvConf = lib.mkForce false;
    networking.useDHCP = lib.mkForce true;

  };
}