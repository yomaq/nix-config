{ options, config, lib, pkgs, ... }:
with lib;
let
  cfg = config.yomaq.adguardhome;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
in
{
  options.yomaq.adguardhome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom adGuard Home module
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.persistence."${backup}" = {
      directories = [
        "/var/lib"
      ];
    };
    services.adguardhome = {
      enable = true;
      allowDHCP = true;
    };
  };
}


