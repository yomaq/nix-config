{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.scripts;
in
{
  options.yomaq.scripts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        install custom scripts
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (import (inputs.self + /modules/scripts/initrdunlock.nix) { inherit pkgs inputs; })
    ];
  };
}
