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

    wsl.enable = true;
    wsl.defaultUser = "admin";
    wsl.useWindowsDriver = true;



    services.open-webui.enable = true;
    services.ollama = {
      enable = true;
      acceleration = "cuda";
      loadModels = [ "deepseek-r1:7b" ];
    };

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
