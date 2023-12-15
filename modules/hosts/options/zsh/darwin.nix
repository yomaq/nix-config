{ config, pkgs, ... }:
with lib;
let
  cfg = config.yomaq.zsh;
in
{
 config = lib.mkIf cfg.enable {
  config.programs.zsh.enable = true;
 };
}