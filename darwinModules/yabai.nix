{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      yabai = {
        enable = true;
      };
    };
  };
}
