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
    # import users
    (inputs.self + /users/admin)
    inputs.nixos-wsl.nixosModules.default
  ];
  config = {
    networking.hostName = "wsl";
    system.stateVersion = "24.05";

    wsl.enable = true;
    wsl.defaultUser = "admin";

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
