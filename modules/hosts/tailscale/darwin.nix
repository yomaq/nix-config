{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# why am I not just using the tailscale service directly? ... idk, it auto configures the authKeyFile?
let
  cfg = config.yomaq.tailscale;
in
{
  config = lib.mkIf cfg.enable { homebrew.casks = [ "tailscale" ]; };
}
