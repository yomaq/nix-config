{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  nix = {
    gc = {
      automatic = true;
      interval.hour = 1;
      options = "--delete-older-than 30d";
    };
  };
}