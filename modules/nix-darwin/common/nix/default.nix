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
  services.nix-daemon.enable = true;
}