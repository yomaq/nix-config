{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
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

    environment.systemPackages = [pkgs.dbus];
    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
        ];
        useRoutingFeatures = "client";
        authKeyFile = null;
      };
      nvidia = {
        enable = true;
        wsl = true;
      };
      docker.enable = true;
      pods = {
        ollama.enable = true;
        open-webui.enable = true;
      };
      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      timezone.central = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
    };
  };
}
