{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.tmux;
in
{
  imports = [ ];
  options.yomaq.tmux = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom tmux module
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      tmux = {
        enable = true;
        shell = if pkgs ? zsh then "${pkgs.zsh}/bin/zsh" else "${pkgs.bash}/bin/bash";
      };
    };
  };
}
