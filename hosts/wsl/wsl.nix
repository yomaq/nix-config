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
    inputs.nixos-wsl.nixosModules.default
  ];
  config = {
    networking.hostName = "wsl";
    system.stateVersion = "24.05";

    wsl.enable = true;
    wsl.defaultUser = "admin";
    wsl.useWindowsDriver = true;

    yomaq = {
      nvidia = {
        enable = true;
        wsl = true;
      };
      suites.foundation.enable = true;
      suites.wsl.enable = true;
    };
  };
}
