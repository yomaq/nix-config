{ config, lib, pkgs, ... }: {
#At the time of making the config nix breaks when darwin documentation is enabled.
  documentation = {
    enable = false;
  };
}