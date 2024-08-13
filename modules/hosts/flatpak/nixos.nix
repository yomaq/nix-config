{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.flatpak;
  inherit (config.yomaq.impermanence) dontBackup;
in
{
  options.yomaq.flatpak = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom flatpak module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    environment.persistence."${dontBackup}" = {
      hideMounts = true;
      directories = [ "/var/lib/flatpak" ];
    };
  };
}
