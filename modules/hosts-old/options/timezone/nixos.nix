{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.timezone;
in
{
  options.yomaq.timezone = {
    central = mkOption {
      type = types.bool;
      default = false;
      description = ''
      '';
    };
  };

  config = mkMerge [
      (mkIf cfg.central {
      # Set your time zone.
      time.timeZone = "America/Chicago";
      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    })
  ];
}