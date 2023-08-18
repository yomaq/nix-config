{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      tailscale = {
        enable = true;
      };
    };
  };
}
