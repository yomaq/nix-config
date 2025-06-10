{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    inputs.nixos-wsl.nixosModules.default
  ];
  config = {
    networking.hostName = "wsl";
    system.stateVersion = "24.05";

    # autostarting wsl with a scheduled task to launch at startup with the command `wsl.exe dbus-launch true`
    # based off https://guides.hakedev.com/wiki/windows/WSL/wsl-auto-start/

    wsl.enable = true;
    wsl.defaultUser = "admin";
    wsl.useWindowsDriver = true;

    environment.systemPackages = [ pkgs.dbus ];

    yomaq = {
      nvidia = {
        enable = true;
        wsl = true;
      };
      suites.foundation.enable = true;
      syncoid.enable = lib.mkForce false;
    };
  };
}
