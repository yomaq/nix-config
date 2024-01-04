{ config, lib, pkgs, ... }: {
#Garbage collection for the Nix Store
  nix = {
#Nix Store config, hard linking identical dependancies etc.
    settings = {
      auto-optimise-store = true;
      sandbox = true;
      allowed-users = [
        "carln"
      ];
    };
  };
  #At the time of making the config nix breaks when darwin documentation is enabled.
    documentation = {
      enable = false;
    };
  services.nix-daemon.enable = true;
}