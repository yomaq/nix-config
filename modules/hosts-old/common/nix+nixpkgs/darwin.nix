{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  nix = {
    gc = {
      automatic = true;
      interval.Hour = 1;
      options = "--delete-older-than 30d";
    };
  };
}