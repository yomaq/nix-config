{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.suites.wsl;
in
{
  options.yomaq.suites.wsl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
  };

  config = lib.mkIf cfg.enable {
    # autostarting wsl with a scheduled task to launch at startup with the command `wsl.exe dbus-launch true`
    # based off https://guides.hakedev.com/wiki/windows/WSL/wsl-auto-start/
    environment.systemPackages = [ pkgs.dbus ];

    services.resolved.enable = lib.mkForce false;

    environment.persistence."/persist/save".enableWarnings = lib.mkForce false;
    environment.persistence."/persist".enableWarnings = lib.mkForce false;
  };
}
